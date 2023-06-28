{ config, pkgs, lib, nixgl } :
{
nixGLWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
    mkdir $out
    ln -s ${pkg}/* $out
    rm $out/bin
    mkdir $out/bin
    for bin in ${pkg}/bin/*; do
     wrapped_bin=$out/bin/$(basename $bin)
     echo "exec ${lib.getExe nixgl.nixGLIntel} $bin \"\$@\"" > $wrapped_bin
     chmod +x $wrapped_bin
    done
  '';
  nixVulkanWrap = pkg: pkgs.runCommand "${pkg.name}-nixgl-wrapper" {} ''
    mkdir $out
    ln -s ${pkg}/* $out
    rm $out/bin
    mkdir $out/bin
    for bin in ${pkg}/bin/*; do
     wrapped_bin=$out/bin/$(basename $bin)
     echo "exec ${lib.getExe nixgl.nixVulkanIntel} $bin \"\$@\"" > $wrapped_bin
     chmod +x $wrapped_bin
    done
  '';

}
