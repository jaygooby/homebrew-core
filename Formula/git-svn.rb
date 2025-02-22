class GitSvn < Formula
  desc "Bidirectional operation between a Subversion repository and Git"
  homepage "https://git-scm.com"
  url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.35.0.tar.xz"
  sha256 "47e677b475226857ceece569fb6ded8b85838ede97ae1e01bd365ac32a468fc8"
  license "GPL-2.0-only"
  head "https://github.com/git/git.git", branch: "master"

  livecheck do
    formula "git"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_monterey: "d25684f1f8a0031fa538b7534e1620a9d2393fffae9065c3ffeaad34d108ab62"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "07dbbbc2b9abc566e62a16c0de8964dbdc825b22506d6ed12a1c9c8474527ddc"
    sha256 cellar: :any_skip_relocation, monterey:       "d25684f1f8a0031fa538b7534e1620a9d2393fffae9065c3ffeaad34d108ab62"
    sha256 cellar: :any_skip_relocation, big_sur:        "07dbbbc2b9abc566e62a16c0de8964dbdc825b22506d6ed12a1c9c8474527ddc"
    sha256 cellar: :any_skip_relocation, catalina:       "53c8ae93e3fe75458d3b3e422817fa183e2a99ec55dfe6cddf3d23e51c95dd51"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "1fc9395d1980279cd2d9e2c20cf04a7e689dbb2314237d0ff2695a3b58117401"
  end

  depends_on "git"
  depends_on "subversion"

  uses_from_macos "perl"

  def install
    perl = DevelopmentTools.locate("perl")
    perl_version, perl_short_version = Utils.safe_popen_read(perl, "-e", "print $^V")
                                            .match(/v((\d+\.\d+)(?:\.\d+)?)/).captures

    ENV["PERL_PATH"] = perl
    ENV["PERLLIB_EXTRA"] = Formula["subversion"].opt_lib/"perl5/site_perl"/perl_version/"darwin-thread-multi-2level"
    if OS.mac?
      ENV["PERLLIB_EXTRA"] += ":" + %W[
        #{MacOS.active_developer_dir}
        /Library/Developer/CommandLineTools
        /Applications/Xcode.app/Contents/Developer
      ].uniq.map do |p|
        "#{p}/Library/Perl/#{perl_short_version}/darwin-thread-multi-2level"
      end.join(":")
    end

    args = %W[
      prefix=#{prefix}
      perllibdir=#{Formula["git"].opt_share}/perl5
      SCRIPT_PERL=git-svn.perl
    ]

    mkdir libexec/"git-core"
    system "make", "install-perl-script", *args

    bin.install_symlink libexec/"git-core/git-svn"
  end

  test do
    system "svnadmin", "create", "repo"

    url = "file://#{testpath}/repo"
    text = "I am the text."
    log = "Initial commit"

    system "svn", "checkout", url, "svn-work"
    (testpath/"svn-work").cd do |current|
      (current/"text").write text
      system "svn", "add", "text"
      system "svn", "commit", "-m", log
    end

    system "git", "svn", "clone", url, "git-work"
    (testpath/"git-work").cd do |current|
      assert_equal text, (current/"text").read
      assert_match log, pipe_output("git log --oneline")
    end
  end
end
