{ pkgs, lib, config, ... }:
with lib;
let
  shouldWrite = maybeNull: optionalString (maybeNull != null && maybeNull != false);

  buildMemory = memory: ''
    <memory unit="${memory.unit}">${toString memory.size}</memory>
  '';

  buildCPU = v: if v.customConfig != null then v.customConfig else 
    if v.cpuMode == "qemu64" then ''
      <cpu mode="custom" match="exact" check="none">
        <model fallback="allow">qemu64</model>
      </cpu>
    '' else if v.cpuMode == "host-passthrough" then ''
      <cpu mode="host-passthrough" check="none" migratable="on"/>
    '' else if v.cpuMode == "host-model" then ''
      <cpu mode="host-model" check="partial"/>
    '' else throw "unsupported cpuMode: ${v.cpuMode}";

  buildvCPU = v: ''
    <vcpu 
      ${shouldWrite v.current ''current="${toString v.current}"''}
      ${shouldWrite v.cpuset ''cpuset="${v.cpuset}"''}
      ${shouldWrite v.placement ''placement="${v.placement}"''}
    >${toString v.size}</vcpu>
  '';

  buildOS = os: ''
    <os ${shouldWrite os.firmware ''firmware="${os.firmware}"''}>
      ${shouldWrite os.loader ''
        <loader 
          ${shouldWrite os.loader.readonly ''readonly=${os.loader.readonly}''}
          ${shouldWrite os.loader.type ''readonly=${os.loader.type}''}
          ${shouldWrite os.loader.secure ''secure=${os.loader.secure}''}>
          ${os.loader.path}
        </loader>
      ''}
      <type
        ${shouldWrite os.type.machine ''machine="${os.type.machine}"''}
      >${os.type.content}</type>
      ${builtins.concatStringsSep "\n" (map (boot: ''
        <boot dev="${boot}"/>
      '') os.bootOrder)}
      ${shouldWrite os.enableBootMenu ''
        <bootmenu enable="yes"/>
      ''}
    </os>
  '';

  buildCPUTune = t: ''
    <cputune>
        ${shouldWrite t.shares ''
          <shares>${toString t.shares}</shares>
        ''}
        ${shouldWrite t.period ''
          <period>${toString t.period}</period>
        ''}
        ${shouldWrite t.quota ''
          <quota>${toString t.quota}</quota>
        ''}
    </cputune>
  '';

  buildFeatures = f: ''
    <features>
      ${shouldWrite f.acpi ''
          <acpi/>
        ''}
      ${shouldWrite f.apic ''
          <apic/>
        ''}
    </features>
  '';

  buildDeviceDisk = d: ''
    <disk type="${d.type}" device="${d.device}">
        ${shouldWrite d.driver ''
          <driver name="${d.driver.name}" 
                  ${shouldWrite d.driver.type ''type="${d.driver.type}"''} 
          />
        ''}
        ${shouldWrite d.source ''
          <source 
            ${shouldWrite d.source.file ''file="${d.source.file}"''}
          />
        ''}
        ${shouldWrite d.target ''
          <target ${shouldWrite 
                  d.target.dev ''
                dev='${d.target.dev}' 
              ''}
                  ${shouldWrite d.target.bus ''bus="${d.target.bus}"''}
          />
        ''}
        ${shouldWrite d.readonly ''
          <readonly/>
        ''}
    </disk>
  '';

  buildDeviceFileSystem = d: ''
    <filesystem type='${d.type}' accessmode='${d.accessmode}'>
      ${shouldWrite d.driver ''
        <driver type="${d.driver.type}" 
                ${shouldWrite d.driver.format ''format="${d.driver.format}"''} 
        />
      ''}
      ${shouldWrite d.binary ''
      <binary path='${d.binary.path}' xattr='${d.binary.xattr}'>
        <cache mode='${d.binary.cacheMode}'/>
        ${shouldWrite d.binary.lock ''
          <lock posix='${d.binary.lock.posix}' flock='${d.binary.lock.flock}'/>
        ''}
      </binary>
      ''}
      ${shouldWrite d.source ''
        <source ${shouldWrite d.source.file ''file="${d.source.file}"''} 
                ${shouldWrite d.source.dir ''dir="${d.source.dir}"''} 
                ${shouldWrite d.source.socket ''socket="${d.source.socket}"''} 
        />
      ''}
      ${shouldWrite d.target ''
        <target dir='${d.target.dir}'/>
      ''}
      ${shouldWrite d.readonly ''
        <readonly/>
      ''}
    </filesystem>
  '';

  buildDeviceInput = i: ''
    <input type='${i.type}' 
          ${shouldWrite i.bus ''
            bus='${i.bus}'
          ''}>
      ${shouldWrite i.source ''
        <source dev='${i.source.dev}' 
                ${shouldWrite i.source.grab "grab='${i.source.grab}'"}
                ${shouldWrite i.source.repeat "repeat='${i.source.repeat}'"}
                ${shouldWrite i.source.grabToggle "grabToggle='${i.source.grabToggle}'"}
        />
      ''}
    </input>
  '';

  buildDeviceGraphics = g: ''
    <graphics type='${g.type}'>
       ${shouldWrite g.listen ''
        <listen type='${g.listen.type}' 
                ${shouldWrite g.listen.socket "socket='${g.listen.socket}'"}
        />
        ${shouldWrite g.opengl ''
          <gl ${shouldWrite g.opengl.enable "enable='${g.opengl.enable}'"} ${shouldWrite g.opengl.rendernode "rendernode='${g.opengl.rendernode}'"}/>
        ''}
       ''}
    </graphics>
  '';

  buildHostDev = h: ''
    <hostdev mode='${h.mode}' type='${h.type}' managed='${h.managed}'>
      <source ${shouldWrite h.source.writeFiltering ''writeFiltering='${h.source.writeFiltering}' ''}>
        <address domain='${h.source.address.domain}'
                bus='${h.source.address.bus}'
                slot='${h.source.address.slot}'
                function='${h.source.address.function}'
        />
      ${shouldWrite h.rom ''
        <rom bar='${h.rom.bar}' file='${h.rom.file}'/>
      ''}
      </source>
    </hostdev>
  '';

  buildDeviceInterface = f: ''
    <interface type="${f.type}" 
              ${shouldWrite f.managed ''
                managed='${f.managed}'
              ''}
    >
        ${shouldWrite f.source ''
          <source 
             ${shouldWrite f.source.bridge ''
              bridge='${f.source.bridge}'
             ''}
          />
        ''}
        ${shouldWrite f.target ''
        <target 
              ${shouldWrite 
                  f.target.dev ''
                dev='${f.target.dev}' 
              ''}
              ${shouldWrite f.target.managed ''
                managed='${f.target.managed}'
              ''}/>
        ''}
        ${shouldWrite f.model ''
        <model type="${f.model.type}" />
        ''}
        ${shouldWrite f.mac ''
        <mac address="${f.mac.address}" />
        ''}
    </interface>
  '';

  buildDeviceSerial = d: ''
    <serial type="${d.type}">
      ${shouldWrite d.target ''
        <target ${shouldWrite d.target.type ''type="${d.target.type}"''}
                ${shouldWrite d.target.port ''port="${d.target.port}"''}
        >
          ${shouldWrite d.target.model ''
            <model name="${d.target.model.name}" />
          ''} 
        </target>
      ''}
    </serial>
  '';

  buildDeviceConsole = d: ''
    <console type="${d.type}">
      ${shouldWrite d.target ''
        <target ${shouldWrite d.target.type ''type="${d.target.type}"''}
                ${shouldWrite d.target.port ''port="${d.target.port}"''}
        />
      ''}
    </console>
  '';

  buildDeviceVideo = d: ''
    <video>
      ${shouldWrite d.model ''
        <model ${shouldWrite d.model.type ''type="${d.model.type}"''}>
          ${shouldWrite d.model."3daccel" ''
            <acceleration accel3d="yes"/>
          ''}
        </model>
      ''}
    </video>
  '';

  buildDevices = d: ''
    <devices>
      ${builtins.concatStringsSep "\n" (map buildDeviceInput (lib.attrsets.mapAttrsToList (n: v: v) d.input))}
      ${builtins.concatStringsSep "\n" (map buildDeviceGraphics (lib.attrsets.mapAttrsToList (n: v: v) d.graphics))}
      ${builtins.concatStringsSep "\n" (map buildDeviceDisk (lib.attrsets.mapAttrsToList (n: v: v) d.disk))}
      ${builtins.concatStringsSep "\n" (map buildDeviceFileSystem (lib.attrsets.mapAttrsToList (n: v: v) d.filesystem))}
      ${builtins.concatStringsSep "\n" (map buildDeviceInterface (lib.attrsets.mapAttrsToList (n: v: v) d.interface))}
      ${builtins.concatStringsSep "\n" (map buildHostDev (lib.attrsets.mapAttrsToList (n: v: v) d.hostdev))}
      ${builtins.concatStringsSep "\n" (map buildDeviceConsole (lib.attrsets.mapAttrsToList (n: v: v) d.console))}
      ${builtins.concatStringsSep "\n" (map buildDeviceSerial (lib.attrsets.mapAttrsToList (n: v: v) d.serial))} 
      ${builtins.concatStringsSep "\n" (map buildDeviceVideo (lib.attrsets.mapAttrsToList (n: v: v) d.video))} 
      ${d.extraConfig}
    </devices>
  '';

  buildMemoryBacking = md: ''
    <memoryBacking>
    ${shouldWrite md.sourceType ''
      <source type='${md.sourceType}'/>
    ''}
      <access mode='${md.accessMode}'/>
    </memoryBacking>
  '';

  domainXmlDefinition = name: domain:
    let
      memory = domain.memory;
      cpu = domain.cpu;
      vcpu = domain.vcpu;
      cputune = domain.cputune;
      os = domain.os;
      devices = domain.devices;
      memoryBacking = domain.memoryBacking;
      features = domain.features;
    in
    ''
      <domain type="${domain.type}">
        <name>${name}</name>
        <uuid>${domain.uuid}</uuid>
        ${if memoryBacking != null then buildMemoryBacking memoryBacking else ""}
        ${buildMemory memory}
        ${buildCPU cpu}
        ${buildvCPU vcpu}
        ${buildFeatures features}
        ${if cputune != null then buildCPUTune cputune else ""}
        ${buildOS os}

        ${buildDevices devices}

        ${domain.extraConfig}
      </domain>
    '';

  cfg = config.turbo.virtualization.libvirt;
  files = attrsets.mapAttrs
    (n: v: pkgs.runCommand "${n}.xml"
      {
        xml = domainXmlDefinition n v;
        nativeBuildInputs = with pkgs; [ libxml2 libvirt ];
      } ''
      echo $xml | xmllint --format - > $out
      virt-xml-validate $out domain
    '')
    cfg.domains;
in
{
  options = {
    turbo.virtualization.libvirt.domains = mkOption {
      type = types.attrsOf (types.submodule ./domain.nix);
      default = { };
      description = ''
        Set of Domains(Machines) defined on Host
      '';
    };

    turbo.virtualization.libvirt._finalXML = lib.mkOption {
      description = ''
        final xml content, this is automatically generated from the settings and should't be touch manually.
      '';
      type = types.attrsOf types.package;
      default = { };
      internal = true;
    };
  };

  config = {
    turbo.virtualization.libvirt._finalXML = files;
  };
}
