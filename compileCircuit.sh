#!/bin/bash
# 设定参数
slotNum=4
randLength=128
bitLength=248
reserveLength=128
maxSelectedSlot=1

# 使用sed命令替换Circom文件中的参数行
sed -i "s/component main .*/component main {public \[otpHash, lastRoundReserveOutput\]} = VerifyXorAndSlot($slotNum, $randLength, $bitLength, $reserveLength, $maxSelectedSlot);/" verifyXorAndSlot.circom

# 编译电路
echo "开始编译 Circom 电路..."
echo "Circom compilation time:" > time.log
{ time circom verifyXorAndSlot.circom --r1cs --wasm --sym; } 2>> time.log
echo "编译完成。时间记录已保存到 time.log。"

# 生成input.json
python generateInput.py $slotNum $randLength $bitLength $reserveLength

sleep 3
echo "开始生成见证文件..."
cd verifyXorAndSlot_js
echo "Witness generation time:" >> ../time.log
{ time node generate_witness.js verifyXorAndSlot.wasm input.json witness.wtns; } 2>> ../time.log
echo "见证文件生成完成。时间记录已保存到 time.log。"

# 开始“tau 的权力”仪式
echo "开始新的 Tau 的权力仪式..."
echo "Powers of Tau new ceremony time:" >> ../time.log
# { time snarkjs powersoftau new bn128 12 pot12_0000.ptau -v; } 2>> ../time.log
{ time snarkjs powersoftau new bn128 18 pot12_0000.ptau -v; } 2>> ../time.log

# Tau 的权力仪式第一次贡献
echo "进行 Tau 的权力仪式第一次贡献..."
echo "First contribution to Powers of Tau time:" >> ../time.log
echo "random text" | { time snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v; } 2>> ../time.log

# 准备阶段 2
echo "准备阶段 2..."
echo "Prepare phase 2 time:" >> ../time.log
{ time snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v; } 2>> ../time.log

# 开始生成 zkey 文件
echo "生成 zkey 文件..."
echo "ZKey generation time:" >> ../time.log
{ time snarkjs groth16 setup ../verifyXorAndSlot.r1cs pot12_final.ptau verifyXorAndSlot_0000.zkey; } 2>> ../time.log

# Tau 的权力仪式阶段2第一次贡献
echo "进行 Tau 的权力仪式阶段2第一次贡献..."
echo "Second contribution to ZKey time:" >> ../time.log
echo "random text" | { time snarkjs zkey contribute verifyXorAndSlot_0000.zkey verifyXorAndSlot_0001.zkey --name="1st Contributor Name" -v; } 2>> ../time.log


# 导出验证密钥
echo "导出验证密钥..."
echo "Verification key export time:" >> ../time.log
{ time snarkjs zkey export verificationkey verifyXorAndSlot_0001.zkey verification_key.json; } 2>> ../time.log

# 生成证明
echo "生成证明..."
echo "Proof generation time:" >> ../time.log
{ time snarkjs groth16 prove verifyXorAndSlot_0001.zkey witness.wtns proof.json public.json; } 2>> ../time.log

# 验证证明
echo "验证证明..."
echo "Proof verification time:" >> ../time.log
{ time snarkjs groth16 verify verification_key.json public.json proof.json; } 2>> ../time.log
echo "所有步骤完成。请查看各个 log 文件获取时间记录。"