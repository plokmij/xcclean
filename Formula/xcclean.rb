# Homebrew formula for xcclean
class Xcclean < Formula
  desc "Xcode Storage Cleaner CLI - Clean DerivedData, Archives, Device Support, and more"
  homepage "https://github.com/your-username/xcclean"
  url "https://github.com/your-username/xcclean/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"
  head "https://github.com/your-username/xcclean.git", branch: "main"

  depends_on :macos

  def install
    # Install library files
    (lib/"xcclean").install Dir["lib/*.sh"]

    # Install binary
    bin.install "bin/xcclean"

    # Install completions
    bash_completion.install "completions/xcclean.bash" => "xcclean"
    zsh_completion.install "completions/xcclean.zsh" => "_xcclean"
    fish_completion.install "completions/xcclean.fish"
  end

  def caveats
    <<~EOS
      To get started, run:
        xcclean --help

      For interactive mode:
        xcclean

      To scan for cleanable items:
        xcclean scan
    EOS
  end

  test do
    assert_match "xcclean version", shell_output("#{bin}/xcclean --version")
    assert_match "Mac Storage Overview", shell_output("#{bin}/xcclean status")
  end
end
