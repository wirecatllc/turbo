# Fun config generators (not really)
{ lib }:
with builtins;
let
  optionalField = arg: stanza: if arg == null || arg == "" then "" else stanza;

  # Render a list, empty list is not supported
  # https://bird.network.cz/pipermail/bird-users/2019-September/013763.html
  renderList = list: assert (lib.assertMsg (length list != 0) "Empty list is not supported!"); "[ ${concatStringsSep ", " list} ]";

  # Render address configurations for a network (DFZ, DN42)
  renderNetworkStanza = let
    renderIp = routercfg: key:
      if routercfg.addresses."${key}" == null
      then "0.0.0.0"
      else routercfg.addresses."${key}";
  in
    name: ipv4: ipv6: config: let routercfg = config.turbo.networking.routing; in ''
      define ${name}_ENABLED = ${if routercfg.addresses."${ipv4}" == null && routercfg.addresses."${ipv6}" == null then "false" else "true"};
      define ${name}_IP4 = ${renderIp routercfg ipv4};
      define ${name}_IP6 = ${renderIp routercfg ipv6};
    '';

  # Render a filter
  renderFilter = default: usercfg: if (isString usercfg) then usercfg else ''
    ${usercfg.prepend}
    ${default}
    ${usercfg.append}
  '';

  # Render a list of params
  renderParams = let
    genCommunity = ld1: ld2: "(IBGP_ASN, ${ld1}, ${ld2})";
    genRelationship = rel: lib.lists.flatten [(
      if rel == "upstream" || rel == "ixp" then (
        genCommunity "RELATIONSHIP" "REL_UPSTREAM"
      )
      else if rel == "downstream" || rel == "collector" then (
        genCommunity "RELATIONSHIP" "REL_DOWNSTREAM"
      )
      else if rel == "bilateral" then [
        (genCommunity "RELATIONSHIP" "REL_UPSTREAM")
        (genCommunity "RELATIONSHIP" "REL_DOWNSTREAM")
      ]
      else if rel == "peer" then (
         genCommunity "RELATIONSHIP" "REL_PEER"
      )
      else "*** ERROR: Unknown relationship ${rel} ***"
    )];
    genNetwork = network: [(
      if network == "dfz" then (
        genCommunity "NETWORK" "NET_DFZ"
      )
      else if network == "dn42" then (
        genCommunity "NETWORK" "NET_DN42"
      )
      else "*** ERROR: Unknown network ${network} ***"
    )];

    genExtraParams = params: map (n: genCommunity (elemAt n 0) (elemAt n 1)) params;

  in relationship: network: extraParams:
      renderList ((genRelationship relationship)
                 ++ (genNetwork network) 
                 ++ (genExtraParams extraParams));
in rec {
  # node.conf
  nodeConf = {
    routerId,
    numericId,
    iBgpAsn,
    communityAsn,
    ownPrefixes6,
    ownPrefixes4,
    region ? null,

    config,
  }: let
    compRegion = 
      if region == null then 0
      else {
        eu = 41;
        na_e = 42;
        na_c = 43;
        na_w = 44;
        ap_s = 50;
        ap_se = 51;
        ap_e = 52;
        ap_o = 53; # Oceania
      }.${region}
    ;
  in ''
    router id ${routerId};
    define NODE_ID = ${toString numericId};
    define REGION = ${toString compRegion};

    define IBGP_ASN = ${toString iBgpAsn};
    define COMMUNITY_ASN = ${toString communityAsn};
    define OWN_PREFIXES6 = ${renderList ownPrefixes6};
    define OWN_PREFIXES4 = ${renderList ownPrefixes4};

    ${renderNetworkStanza "DFZ" "v4" "v6" config}
    ${renderNetworkStanza "DN42" "dn4" "dn6" config}
  '';

  # A BGP session
  bgpSession = {
    name, description,

    localAS, peerAS, realPeerAS, neighbor,
    iBgp, rr, protocols, addPaths, multihop, sourceAddress, password,
    prefixes, importFilter, exportFilter,
    relationship, localPref, network, nextHopKeep,
    extraChannelConfigs, extraConfigs,

    config, ...
  } @ context:
    if iBgp
    then (iBgpSession context)
    else (eBgpSession context);

  # An eBGP session
  eBgpSession = {
    name, description,

    localAS, peerAS, realPeerAS, neighbor,
    iBgp, protocols, addPaths, multihop, sourceAddress, password,
    prefixes, importFilter, exportFilter,
    relationship, localPref, network, nextHopKeep,
    extraChannelConfigs, extraConfigs,
    extraParams,

    config, ...
  }: let
    compRealPeerAS = if realPeerAS == null then peerAS else realPeerAS;
    compDescription = if description == null then "AS${toString compRealPeerAS}" else description;
    compMultihop = if multihop == true then "multihop;" else if multihop == false then "direct;" else "multihop ${toString multihop};";
    compSourceAddress = if sourceAddress == null then "" else "source address ${sourceAddress};";
    compPassword = if password == null then "" else "password \"${password}\";";
    compAddPaths = if addPaths == false then "" else "add paths ${addPaths};";
    compImportFilter = renderFilter ''
      common_import_filter(${toString compRealPeerAS}, ${toString localAS}, ${renderParams relationship network extraParams});
    '' importFilter;
    compExportFilter = renderFilter ''
      common_export_filter(${toString compRealPeerAS}, ${toString localAS}, ${renderParams relationship network extraParams});
    '' exportFilter;
    compLocalPref = if localPref != null then "default bgp_local_pref ${toString localPref};" else (
      if relationship == "ixp" then "default bgp_local_pref 300;"
      else if relationship == "upstream" then "default bgp_local_pref 200;"
      else ""
    );
    renderChannel = channel: ''
      ${channel} {
        ${compAddPaths}

        import filter {
          ${compImportFilter}
        };

        export filter {
          ${compExportFilter}
        };
        ${if elem channel nextHopKeep then "next hop keep;" else ""}
        ${if hasAttr channel extraChannelConfigs then extraChannelConfigs.${channel} else ""}
      };
    '';
    renderChannels = protocols: concatStringsSep "\n" (map renderChannel protocols);
  in ''
    protocol bgp ${name} {
      description "${compDescription}";
      local as ${toString localAS};
      neighbor ${neighbor} as ${toString peerAS};
      ${compMultihop}
      ${compSourceAddress}
      ${compPassword}
      ${compLocalPref}
      ${renderChannels protocols}

      ${extraConfigs}
    };
  '';

  iBgpSession = {
    name, description, neighbor,
    protocols, rr, addPaths, password,
    importFilter, exportFilter, ibgpExportExternal,
    extraChannelConfigs, extraConfigs, extraParams,

    config, ...
  }: let
    compDescription = if description == null then "AS${toString compRealPeerAS}" else description;
    compAddPaths = if addPaths == false then "" else "add paths ${addPaths};";
    compPassword = if password == null then "" else "password \"${password}\";";
    compRr = if rr then "rr client;" else "";

    compImportFilter = renderFilter ''
      ibgp_import_filter();
    '' importFilter;
    compExportFilter = renderFilter ''
      ${if ibgpExportExternal then "" else "reject_external_routes();"}
      ibgp_export_filter();
    '' exportFilter;
  in ''
    protocol bgp ${name} {
      description "${compDescription}";
      local as IBGP_ASN;
      neighbor ${neighbor} as IBGP_ASN;
      ${compPassword}
      ${compRr}

      ipv4 {
        import filter {
          ${compImportFilter}
        };
        export filter {
          ${compExportFilter}
        };
        ${compAddPaths}
      };

      ipv6 {
        import filter {
          ${compImportFilter}
        };
        export filter {
          ${compExportFilter}
        };
        ${compAddPaths}
      };

      ${extraConfigs}
    };
  '';


  staticProtocol = {
    name, description, protocol, table, routes, importFilter,
    config, extraChannelConfigs, ...
  }: let
    compDescription = if description == null then "${name} static routes" else description;
    compRoutes = concatStringsSep "\n" (map (r: "route ${r};") routes);
    compImportFilter = renderFilter ''
      static_protocol_filter();
    '' importFilter;
  in ''
    protocol static ${name} {
      description "${compDescription}";
      ${protocol} {
        ${lib.optionalString (table != null) "table ${table};"}
        ${extraChannelConfigs}
        preference 65535;
        import filter {
          ${compImportFilter}
        };
      };
      ${compRoutes};
    };
  '';
  ospfProtocol = {
    name, description, version, protocol, areas,
    extraConfigs, extraChannelConfigs, ...
  }: let
    compDescription = if description == null then "OSPF ${name}" else description;
    # v4 -> v3
    compVersion = if version == null then { ipv4 = "v2"; ipv6 = "v3"; }.${protocol} else version;
    compTable = { ipv4 = "ospf4"; ipv6 = "ospf6"; }.${protocol};
    compAreas = concatStringsSep "" (lib.attrsets.mapAttrsToList
      (name: v: ospfArea (v // { inherit name; }))
      areas
    );
  in ''
    protocol ospf ${compVersion} ${name} {
      description "${compDescription}";

      ${protocol} {
        table ${compTable};
        ${extraChannelConfigs}
      };
      ${compAreas}
      ${extraConfigs}
    }
  '';

  # Name is only used to facilitate config merging
  # (e.g. I add in shared stub interfaces for backbone
  # in my common.nix)
  ospfArea = {
    name, id, stub, interfaces, extraConfigs
  }: let
    compInterfaces = concatStringsSep "" (lib.mapAttrsToList
      (name: v: ospfInterface (v // { inherit name; }))
      interfaces
    );
    compStub = if stub == "no" then "stub no;"
    else if stub == "stub" then "stub;"
    else if stub == "nssa" then "nssa;"
    else throw "Invalid stub value ${stub}";
  in ''
    area ${toString id} {
      ${compStub}
      ${compInterfaces}
      ${extraConfigs}
    };
  '';

  ospfInterface = {
    name, interfaces, instance, stub, cost, authentication, password,
    extraConfigs
  }: let
    renderInterfaces = interfaces: concatStringsSep ", " (map (x: "\"${x}\"") interfaces);
    compInterfaces = if interfaces == null then renderInterfaces [name] else renderInterfaces interfaces;
    compInstance = optionalField instance "instance ${toString instance}";
    compCost = optionalField cost "cost ${toString cost};";
    compStub = if stub then "stub;" else "";
    compAuthentication = if authentication == null then
      (if password == null then "" else "authentication cryptographic;")
      else "authentication ${authentication};";
    compPassword = optionalField password "password \"${password}\";";
  in ''
    interface ${compInterfaces} ${compInstance} {
      ${compCost}
      ${compStub}
      ${compAuthentication}
      ${compPassword}
      ${extraConfigs}
    };
  '';
}
