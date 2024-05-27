pragma circom 2.0.0;

include "./circomlib/circuits/sha256/sha256.circom" ;

template VerifyXorAndSlot(slotNum, randLength, bitLength, reserveLength, maxSelectedSlot) {
    // step 1: 定义输入、中间变量与输出
    // 每个msg和otp条目表示一个位，每个槽包含bitLength位
    signal input msg[slotNum * bitLength]; // 输入消息数组，按位存储
    signal input selectedSlot[slotNum]; // 选中槽位的数组，每个槽位为1表示选中，为0表示未选中
    signal input otp[slotNum * bitLength]; // 密钥数组，按位存储
    signal input rand[randLength]; // 用户在上一轮次中选择的随机数
    signal input otpHash[256]; // 公有， 服务器公布的用户共享密钥的哈希
    signal input lastRoundReserveOutput[slotNum * reserveLength];// 公有，上一轮次的预约输出结果
    signal output xorResult[slotNum * bitLength]; // 异或结果输出数组，按位存储

    signal selectedMsg[slotNum * bitLength]; // 选中消息后的中间结果存储数组
    signal sumSelectedSlots[slotNum + 1]; // 用于计数选中的槽位数量的累加器
    sumSelectedSlots[0] <== 0; // 初始化累加器的第一个元素为0
    
    // step 2: 检查输入
    assert(slotNum > maxSelectedSlot); // 确保最大选中槽数量小于槽数量
    assert(reserveLength <= 256); // 哈希最大输出256位

    // step 3: 验证预约
    component SHA = Sha256(randLength);
    SHA.in <== rand;
    for (var i = 0; i < slotNum; i++) {
        if (selectedSlot[i] == 1) {
            for (var j = 0; j < reserveLength; j++) {
                var index = i * reserveLength + j;
                assert(lastRoundReserveOutput[index] == SHA.out[j]);
            }
        }
    }

    // step 4: 验证用户的otp
    component SHA_OTP = Sha256(slotNum * bitLength);
    SHA_OTP.in <== otp;
    for (var i = 0; i < 256; i++) {
        assert(otpHash[i] == SHA_OTP.out[i]);
    }

    // step 5: 验证生成输出的过程
    for (var i = 0; i < slotNum; i++) {
        for (var j = 0; j < bitLength; j++) {
            var index = i * bitLength + j;
            
            // 如果槽位选中，将对应消息与选中槽位值相乘，结果存储在selectedMsg中
            selectedMsg[index] <== selectedSlot[i] * msg[index];
            // 对选中的消息和密钥进行异或运算，并存储在xorResult中
            xorResult[index] <== (selectedMsg[index] + otp[index]) - 2 * selectedMsg[index] * otp[index];
        }
        // 累加选中的槽位数
        sumSelectedSlots[i + 1] <== sumSelectedSlots[i] + selectedSlot[i];
    }

    // 断言选中槽位的总数不超过最大允许值
    assert(sumSelectedSlots[slotNum] <= maxSelectedSlot);
}

// slotNum, randLength, bitLength, reserveLength, maxSelectedSlot
component main {public [otpHash, lastRoundReserveOutput]} = VerifyXorAndSlot(4, 128, 248, 128, 1);
