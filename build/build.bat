cd C:\Users\abderamane\Desktop\opriting system\retros-master\build
nasm ../src/boot.asm -f bin -o ../build/boot.img
nasm ../src/kernel.asm -f bin -o ../build/kernel.img
cd ../build
copy /y /b boot.img + kernel.img retros.img

start boot.bxrc