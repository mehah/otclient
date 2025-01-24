protoc --cpp_out=./ *.proto
move "%cd%\*.cc" "%cd%\..\"
move "%cd%\*.h" "%cd%\..\"
PAUSE
