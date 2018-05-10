MRuby::Build.new do |conf|
  # load specific toolchain settings

  # Gets set by the VS command prompts.
  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end

  conf.bins = []
end

# Cross Compiling configuration for RX630
# http://gadget.renesas.com/
#
# Requires gnurx_v14.03
MRuby::CrossBuild.new("RX630") do |conf|
  toolchain :gcc

  base_path = case RbConfig::CONFIG['host_os']
                when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
                  # Windows
                  "/cygdrive/c/Renesas/GNURXv14.03-ELF/rx-elf/rx-elf/"
                when /darwin|mac os/
                  # macOS
                  "/Applications/IDE4GR.app/Contents/Java/hardware/tools/gcc-rx/rx-elf/rx-elf/"
                when /linux/
                  # Linux
                  "/usr/share/gnurx_v14.03_elf-1/"
              end
  BIN_PATH = base_path + "bin"
  LIB_PATH = base_path + "rx-elf/lib"

  conf.cc do |cc|
    cc.command = "#{BIN_PATH}/rx-elf-gcc"
    cc.flags = "-Wall -g -O2 -flto -mcpu=rx600 -m64bit-doubles -L#{LIB_PATH}/"
    cc.compile_options = "%{flags} -o %{outfile} -c %{infile}"

    cc.include_paths <<= File.dirname(__FILE__) + "/wrbb_eepfile"
    cc.include_paths <<= File.dirname(__FILE__) + "/WavMp3p"

    common_path = File.dirname(__FILE__) + "/gr_common"
    cc.include_paths <<= common_path
    %w(core lib/MsTimer2 lib/RTC lib/SD lib/Servo lib/Wire rx63n).each do |path|
      cc.include_paths <<= common_path + "/#{path}"
    end

    #configuration for low memory environment
    cc.defines << %w(MRB_USE_FLOAT)           # add -DMRB_USE_FLOAT to use float instead of double for floating point numbers
    cc.defines << %w(MRB_FUNCALL_ARGC_MAX=6)  # argv max size in mrb_funcall
    cc.defines << %w(MRB_HEAP_PAGE_SIZE=24)   # number of object per heap page
    cc.defines << %w(MRB_USE_IV_SEGLIST)      # use segmented list for IV table
    cc.defines << %w(MRB_IVHASH_INIT_SIZE=3)  # initial size for IV khash; ignored when MRB_USE_IV_SEGLIST is set
    cc.defines << %w(KHASH_DEFAULT_SIZE=2)    # default size of khash table bucket
    cc.defines << %w(POOL_PAGE_SIZE=256)      # effective only for use with mruby-eval
    cc.defines << %w(MRB_BYTECODE_DECODE_OPTION)  # hooks for bytecode decoder

    cc.defines << %w(ARDUINO=100)             # avoid "WProgram.h not found" at build time
    cc.defines << %w(GRCITRUS)
  end

  conf.cxx do |cxx|
    cxx.command = conf.cc.command.dup
    cxx.include_paths = conf.cc.include_paths.dup
    cxx.flags = conf.cc.flags.dup
    cxx.defines = conf.cc.defines.dup
    cxx.compile_options = conf.cc.compile_options.dup
  end

  conf.linker do |linker|
    linker.command="#{BIN_PATH}/rx-elf-ld"
  end

  conf.archiver do |archiver|
    archiver.command = "#{BIN_PATH}/rx-elf-ar"
    archiver.archive_options = 'rcs %{outfile} %{objs}'
  end

  #no executables
  conf.bins = []

  #do not build executable test
  conf.build_mrbtest_lib_only

  #gems from core
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-numeric-ext"

  conf.gem "./mrbgems/mruby-wrbb-dc-motor"
  conf.gem "./mrbgems/mruby-wrbb-global-const"
  conf.gem "./mrbgems/mruby-wrbb-i2c"
  conf.gem "./mrbgems/mruby-wrbb-kernel-ext"
  conf.gem "./mrbgems/mruby-wrbb-mem"
  conf.gem "./mrbgems/mruby-wrbb-mp3"
  conf.gem "./mrbgems/mruby-wrbb-rtc"
  conf.gem "./mrbgems/mruby-wrbb-sdcard"
  conf.gem "./mrbgems/mruby-wrbb-serial"
  conf.gem "./mrbgems/mruby-wrbb-servo"
  conf.gem "./mrbgems/mruby-wrbb-wifi"
end
