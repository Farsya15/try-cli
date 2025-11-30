# Maintainer: Your Name <your.email@example.com>
pkgname=try-c
pkgver=0.1.0
pkgrel=1
pkgdesc="A fast, interactive CLI tool for managing ephemeral development workspaces"
arch=('x86_64' 'aarch64')
url="https://github.com/tobi/try-c"
license=('MIT')
depends=('glibc')
makedepends=('gcc' 'make')
source=("$pkgname-$pkgver.tar.gz::https://github.com/tobi/try-c/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')  # Replace with actual checksum when available

build() {
    cd "$pkgname-$pkgver"
    make clean
    make
}

check() {
    cd "$pkgname-$pkgver"
    make test
}

package() {
    cd "$pkgname-$pkgver"

    # Install binary
    install -Dm755 try "$pkgdir/usr/bin/try"

    # Install shell integration script
    install -Dm644 init_script.sh "$pkgdir/usr/share/try/init_script.sh"

    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

    # Install documentation
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 docs/*.md "$pkgdir/usr/share/doc/$pkgname/"
}