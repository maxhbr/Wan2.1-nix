{
  description = "Development environment for ComfyUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # pkgs = nixpkgs.legacyPackages.${system};
        pkgs = import nixpkgs { 
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = let 
          ld_packages = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            opencv4WithoutCuda # opencv
            linuxPackages.nvidia_x11
            ncurses5
            mesa
          ];
          in pkgs.mkShell {
            buildInputs = with pkgs; [
              git gitRepo gnupg autoconf curl
              procps gnumake util-linux m4 gperf unzip
              cudatoolkit linuxPackages.nvidia_x11
              libGLU libGL
              xorg.libXi xorg.libXmu freeglut
              xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib 
              ncurses5 stdenv.cc binutils
            ];

            packages = with pkgs; [
              python313
              python313Packages.pip
              #python331Packages.venv

              # Build dependencies that may be needed
              pkg-config
              cmake
              ninja
              gcc

              # System libraries needed for OpenCV and other dependencies

              # Add these to your packages list if you have an NVIDIA GPU
              cudaPackages.cuda_cudart
              # cudaPackages.cuda_runtime
              cudaPackages.cudatoolkit
            ] ++ ld_packages;

            shellHook = ''
              export CUDA_PATH=${pkgs.cudatoolkit}
              export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
              export EXTRA_CCFLAGS="-I/usr/include"
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath ld_packages}:$LD_LIBRARY_PATH

              # Create venv if it doesn't exist
              if [ ! -d "comfyui_env" ]; then
                python3 -m venv comfyui_env
                (
                  source comfyui_env/bin/activate
                  set -x
                  grep -v 'torchaudio\|torchvision' requirements.txt > temp_requirements.txt
                  pip install -r temp_requirements.txt
                  pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
                  pip install "huggingface_hub[cli]"
                  pip install modelscope
                )
              fi
              
              # Activate venv
              source comfyui_env/bin/activate
            '';
          };
      }
    );
} 
