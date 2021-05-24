flutter build windows
mv build/windows/runner/Release ./build-windows
git add .
git commit -m  "${0}"
git push github main
rm  ./build-windows -rf