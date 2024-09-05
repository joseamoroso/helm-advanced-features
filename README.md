# helm-advanced-features

```sh
helm template helm-adv-demo ./charts/helm-advanced-features --post-renderer ./kustomize/kustomize --debug --dry-run
 
cd charts/helm-advanced-features
 
helm plugin install ./plugins/plan-pods-usage
helm plugin install ./plugins/secrets-manager

helm plan-pods-usage .
```
