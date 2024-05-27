## 1 安装Circom和Snarkjs

## 2 设计电路

`circom`允许程序员定义算术电路的约束。我们的电路设计在`verifySlotSelectionAndXOR.circom`中。

## 3 编译电路

使用 circom编写算术电路后，我们应该将其保存在扩展名为 .circom 的文件。 你可以创建自己的电路或使用我们电路库 circomlib中的模板。

在我们的案例中，我们创建了multiplier2.circom文件。现在是编译电路以获得表示它的算术方程组的时候了。作为编译的结果，我们还将获得计算见证的程序。我们可以使用以下命令编译电路：

```
circom verifyXorAndSlot.circom --r1cs --wasm --sym
```

如果要记录编译的时间，可以使用`./compileCircuit.sh`脚本（注意在windows上可能需要再git bash或者wsl环境中运行）
```
./compileCircuit.sh
```