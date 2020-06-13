# cardano-builder

```
podman run --rm --name cardano-builder \
  --volume /tmp:/release \
  localhost/cardano-builder build \
    --cardano_version latest \
    --ghc_version 8.6.5 \
    --os_arch x86_64 \
    --cabal_version 3.2.0.0
```
