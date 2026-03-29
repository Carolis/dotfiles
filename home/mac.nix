{ ... }:

{
  # macOS-specific SSH config (keychain integration)
  programs.ssh.matchBlocks."github.com".extraOptions = {
    UseKeychain = "yes";
  };
}
