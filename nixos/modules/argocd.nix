# Installs Argo CD through k3s's built-in helm controller and points it at the
# repo's cluster/apps folder. k3s applies anything in its manifests directory.
{ config, lib, ... }:

let
  cfg = config.homelab.argocd;
in
{
  options.homelab.argocd = {
    chartVersion = lib.mkOption { type = lib.types.str; default = "10.11.6"; };
    repoURL = lib.mkOption {
      type = lib.types.str;
      default = "http://192.168.0.201:3000/marcosash/homelab.git";
      description = "Repo holding cluster/apps. Switch to the GitHub mirror before the Forgejo box is wiped.";
    };
    revision = lib.mkOption { type = lib.types.str; default = "main"; };
  };

  config.services.k3s.manifests = {
    argocd-namespace.content = {
      apiVersion = "v1";
      kind = "Namespace";
      metadata.name = "argocd";
    };

    argocd-chart.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChart";
      metadata = { name = "argo-cd"; namespace = "kube-system"; };
      spec = {
        repo = "https://argoproj.github.io/argo-helm";
        chart = "argo-cd";
        version = cfg.chartVersion;
        targetNamespace = "argocd";
        # Caddy terminates TLS, so the UI serves plain http on :80
        valuesContent = ''
          configs:
            params:
              server.insecure: true
        '';
      };
    };

    # Everything else in the cluster hangs off this one Application
    argocd-root.content = {
      apiVersion = "argoproj.io/v1alpha1";
      kind = "Application";
      metadata = { name = "root"; namespace = "argocd"; };
      spec = {
        project = "default";
        source = {
          repoURL = cfg.repoURL;
          targetRevision = cfg.revision;
          path = "cluster/apps";
        };
        destination = { server = "https://kubernetes.default.svc"; namespace = "argocd"; };
        syncPolicy = { automated = { prune = true; selfHeal = true; }; };
      };
    };
  };
}
