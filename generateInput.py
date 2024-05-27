import json
import random
import os
import sys
import hashlib

def generate_sha256_hash(bits):
    # 将位数组转换为字节串
    byte_array = bytearray(int(''.join(bits[i:i+8]), 2) for i in range(0, len(bits), 8))
    # 计算 SHA256 哈希
    hash_object = hashlib.sha256(byte_array)
    # 获取哈希值的十六进制表示
    hex_dig = hash_object.hexdigest()
    # 将十六进制转换为二进制位数组
    bin_array = [bin(int(hex_dig[i], 16))[2:].zfill(4) for i in range(len(hex_dig))]
    # 将二进制位数组转换为单个位的字符串数组
    return [bit for group in bin_array for bit in group]

def generate_inputs(slotNum, randLength, bitLength, reserveLength):
    # 生成选中槽位的数组，确保只有一个随机选中的位为1，其余为0
    selectedSlot = [0] * slotNum
    selected_index = random.randint(0, slotNum - 1)
    selectedSlot[selected_index] = 1

    # 生成随机的msg数组，只有选中槽位的位可以是0或1，其余槽位的位都是0
    msg = []
    for i in range(slotNum):
        for j in range(bitLength):
            if i == selected_index:
                msg.append(str(random.randint(0, 1)))  # 选中槽位填随机数0或1
            else:
                msg.append('0')  # 未选中槽位填0
    
    # 生成随机的otp数组，每个位为0或1
    otp = [str(random.randint(0, 1)) for _ in range(slotNum * bitLength)]
    
    # 生成随机的rand数组，每个位为0或1
    rand = [str(random.randint(0, 1)) for _ in range(randLength)]
    
    # 生成otpHash，固定长度为256，每个位为0或1
    # otpHash = [str(random.randint(0, 1)) for _ in range(256)]
    otpHash = generate_sha256_hash(otp)
    
    # 生成lastRoundReserveOutput，每个位为0或1
    randHash = generate_sha256_hash(rand)
    lastRoundReserveOutput = []
    # for i in range(reserveLength):
    #     lastRoundReserveOutput.append(randHash[i])
    for i in range(slotNum):
        for j in range(reserveLength):
            if i == selected_index:
                lastRoundReserveOutput.append(randHash[j])  # 选中槽位填随机数0或1
            else:
                lastRoundReserveOutput.append('0')  # 未选中槽位填0

    # 封装所有数据到一个字典
    inputs = {
        "msg": msg,
        "selectedSlot": selectedSlot,
        "otp": otp,
        "rand": rand,
        "otpHash": otpHash,
        "lastRoundReserveOutput": lastRoundReserveOutput
    }
    
    # 生成JSON文件
    directory = 'verifyXorAndSlot_js'
    if not os.path.exists(directory):
        os.makedirs(directory)
    with open(f'{directory}/input.json', 'w') as json_file:
        json.dump(inputs, json_file, indent=2)

# 示例使用
if __name__ == '__main__':
    if len(sys.argv) != 5:
        print("Usage: python generate_inputs.py slotNum randLength bitLength reserveLength")
        sys.exit(1)
    slotNum = int(sys.argv[1])
    randLength = int(sys.argv[2])
    bitLength = int(sys.argv[3])
    reserveLength = int(sys.argv[4])
    generate_inputs(slotNum, randLength, bitLength, reserveLength)
# generate_inputs(slotNum=32, randLength=128, bitLength=248, reserveLength=128)
