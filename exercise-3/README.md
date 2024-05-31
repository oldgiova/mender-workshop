# Exercise 3: Mender Setup with FluxCD

## Step 1: FluxCD setup

```bash
helm install -n flux-system --create-namespace --wait flux oci://ghcr.io/fluxcd-community/charts/flux2
```
