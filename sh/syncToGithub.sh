http_proxy="http://127.0.0.1:7890"
https_proxy="http://127.0.0.1:7890"
flutter build windows
mv build/windows/runner/Release ./build-windows
git add .
git commit -m  "${0}"
git push github main
rm  ./build-windows -rf
