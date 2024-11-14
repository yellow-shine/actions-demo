name: sync to artifactory
description: download package from conan center and upload it and dpendency to jfrog artifactory
on:
  workflow_dispatch:
    inputs:
      package:
        description: 'The Conan package to install'
        required: true
        default: 'gdal/3.5.3'
      upload:
        description: 'Set to true to perform the upload, false for dry run'
        required: false
        default: 'false'

jobs:
  sync-conan-package:
    runs-on: ubuntu-latest
    env:
      CONAN_REVISIONS_ENABLED: 1
      CONAN_LOGIN_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }}
      CONAN_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.13' 

      - name: Install Conan
        run: |
          pip install --user conan==1.65.0
          conan --version

      - name: Configure Conan remote
        run: |

          conan remote add default-conan-local https://milvus01.jfrog.io/artifactory/api/conan/default-conan-local

      - name: Install package
        run: |
          conan remote list
          conan install ${{ github.event.inputs.package }}@ -s compiler=gcc -s compiler.version=11 -s compiler.libcxx=libstdc++11 -s build_type=Release

      - name: inspect installed package
        run: |
          conan search '*' --revisions

      - name: Upload
        if: ${{ github.event.inputs.upload == 'true' }}
        run: |
          conan upload ${{ github.event.inputs.package }} -r default-conan-local