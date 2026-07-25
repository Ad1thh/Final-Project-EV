_start:
    li x1, 0
    lui x2, 204595
    addi x2, x2, -1559
    lui x3, 1021281
    addi x3, x3, -1557
    lui x4, 866139
    addi x4, x4, -1489
    lui x5, 1017540
    addi x5, x5, 1838
    lui x6, 886753
    addi x6, x6, -1233
    lui x7, 564214
    addi x7, x7, 125
    lui x8, 598771
    addi x8, x8, -1482
    lui x9, 156888
    addi x9, x9, 1200
    lui x10, 260959
    addi x10, x10, -57
    lui x11, 484513
    addi x11, x11, 259
    lui x12, 368885
    addi x12, x12, 644
    lui x13, 330300
    addi x13, x13, -699
    # --- BEGIN CONSTRAINED RANDOM FUZZING ---
    xori x2, x3, -1612
    addi x4, x11, -476
    and x12, x5, x9
    srli x7, x3, 13
    or x8, x10, x2
    srai x13, x12, 19
    or x13, x7, x9
    ori x10, x1, -314
    sra x9, x8, x12
    or x11, x3, x10
    sub x9, x5, x10
    and x1, x13, x2
    slt x13, x13, x4
    sltu x11, x3, x2
    and x9, x12, x2
    # --- VERIFY x6 ---
    lui x14, 886753
    addi x14, x14, -1233
    bne x6, x14, test_fail
    addi x12, x8, -969
    ori x2, x12, -1089
    srl x8, x9, x3
    slli x13, x1, 5
    add x7, x12, x7
    andi x12, x12, -959
    sub x11, x7, x9
    sra x13, x13, x13
    and x11, x11, x6
    srai x4, x5, 17
    or x3, x13, x3
    and x5, x8, x2
    slli x1, x10, 5
    srli x12, x10, 28
    ori x9, x1, -702
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, -574
    bne x9, x14, test_fail
    and x8, x1, x8
    sltu x8, x9, x5
    srai x11, x2, 31
    sra x11, x1, x10
    xori x4, x10, 1295
    slli x3, x8, 27
    slt x6, x11, x9
    add x12, x12, x5
    srl x13, x1, x7
    ori x1, x3, -225
    slli x11, x3, 4
    slli x9, x8, 25
    addi x1, x11, 1671
    sltu x3, x5, x9
    xori x7, x11, -1650
    # --- VERIFY x13 ---
    lui x14, 16384
    addi x14, x14, -157
    bne x13, x14, test_fail
    sll x12, x10, x5
    srai x5, x7, 16
    and x5, x5, x10
    srli x7, x12, 15
    xor x13, x4, x11
    addi x12, x8, -345
    xori x3, x6, -1697
    and x10, x6, x5
    sra x2, x2, x12
    sltu x9, x12, x6
    ori x13, x10, 1821
    slt x8, x13, x1
    andi x2, x5, 1229
    xor x5, x4, x2
    xor x9, x9, x3
    # --- VERIFY x3 ---
    lui x14, 0
    addi x14, x14, -1697
    bne x3, x14, test_fail
    addi x4, x7, 922
    ori x12, x12, -1141
    andi x1, x8, -1357
    add x9, x5, x2
    or x11, x7, x6
    and x4, x13, x13
    add x9, x7, x12
    sll x7, x7, x5
    slli x2, x13, 13
    sltu x11, x4, x8
    srl x10, x12, x8
    srai x4, x13, 16
    srl x6, x12, x4
    srli x6, x6, 8
    srli x4, x1, 13
    # --- VERIFY x2 ---
    lui x14, 3642
    addi x14, x14, 0
    bne x2, x14, test_fail
    srl x8, x9, x1
    srl x4, x2, x7
    ori x5, x8, -526
    ori x13, x1, 1879
    addi x10, x6, -681
    xor x1, x8, x10
    xori x7, x7, 753
    srl x10, x10, x3
    srli x10, x2, 15
    srli x13, x1, 21
    xori x6, x13, -1469
    sub x12, x1, x3
    xori x13, x5, -1243
    add x9, x4, x5
    sra x8, x2, x9
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    add x1, x3, x12
    and x12, x13, x2
    addi x5, x1, 193
    ori x8, x3, 1714
    sra x13, x8, x7
    andi x5, x10, 688
    srai x12, x13, 19
    and x10, x6, x5
    sll x5, x8, x4
    xor x12, x10, x10
    xor x1, x3, x13
    xor x3, x12, x11
    srli x13, x11, 22
    sra x5, x9, x4
    srli x3, x11, 17
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    and x4, x10, x12
    srai x10, x7, 7
    sll x7, x13, x8
    andi x11, x5, 562
    srli x11, x7, 7
    srai x2, x8, 12
    and x11, x2, x4
    ori x5, x8, 1886
    and x12, x2, x12
    or x2, x3, x10
    slli x8, x6, 21
    srli x10, x11, 3
    srai x3, x2, 10
    sra x3, x2, x4
    slli x4, x5, 2
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    srli x10, x3, 8
    xori x9, x4, -1400
    ori x4, x7, -284
    slli x13, x3, 16
    xori x3, x1, -703
    add x10, x10, x1
    xori x8, x8, -1270
    srai x8, x7, 21
    sll x13, x7, x9
    slt x9, x11, x11
    addi x6, x4, 1734
    andi x12, x4, -1927
    sra x6, x9, x6
    srl x4, x4, x12
    srai x6, x1, 18
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    andi x2, x8, -1109
    sll x7, x1, x9
    ori x6, x13, 222
    sltu x5, x2, x1
    xori x3, x6, 1668
    srai x11, x5, 28
    srai x7, x4, 23
    and x5, x12, x4
    addi x11, x6, -907
    sub x10, x6, x9
    addi x4, x3, 1429
    slt x1, x6, x10
    sub x1, x4, x5
    add x1, x7, x7
    and x9, x5, x5
    # --- VERIFY x10 ---
    lui x14, 0
    addi x14, x14, 222
    bne x10, x14, test_fail
    sltu x10, x1, x1
    srl x13, x1, x5
    addi x12, x3, 2026
    sra x8, x8, x2
    srai x10, x9, 3
    sra x11, x11, x2
    add x3, x12, x12
    add x10, x13, x9
    add x11, x11, x11
    srli x6, x7, 28
    sll x1, x9, x9
    xor x2, x7, x3
    addi x2, x13, -1086
    sub x7, x3, x2
    sll x12, x4, x2
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, -1370
    bne x11, x14, test_fail
    sll x4, x6, x3
    srli x4, x13, 23
    srli x10, x13, 7
    sub x13, x10, x11
    slli x9, x12, 4
    or x12, x4, x6
    and x10, x1, x11
    sub x2, x6, x12
    andi x1, x4, 124
    sra x10, x3, x8
    and x3, x12, x5
    slli x13, x3, 5
    and x2, x13, x2
    srli x6, x1, 13
    add x3, x8, x8
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, -1370
    bne x11, x14, test_fail
    ori x13, x11, -1125
    srai x10, x2, 23
    srli x4, x12, 16
    sll x6, x3, x11
    sll x7, x2, x11
    sltu x7, x8, x9
    xori x4, x4, -1574
    sll x7, x1, x11
    add x2, x11, x9
    and x1, x3, x9
    slt x7, x3, x2
    slli x2, x2, 6
    srl x6, x5, x11
    sra x9, x7, x3
    srli x12, x6, 7
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, -1089
    bne x13, x14, test_fail
    sltu x4, x4, x7
    or x11, x8, x11
    sra x6, x11, x4
    slt x11, x6, x13
    slt x4, x13, x5
    slli x4, x6, 12
    slli x9, x8, 12
    slli x9, x10, 24
    sltu x10, x7, x7
    xori x3, x11, 310
    sub x9, x6, x7
    sltu x9, x11, x1
    srl x1, x3, x7
    xori x1, x2, 343
    or x7, x4, x13
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 0
    bne x9, x14, test_fail
    and x12, x7, x5
    sra x10, x8, x6
    srl x9, x2, x12
    srli x3, x9, 19
    srai x5, x2, 4
    srli x1, x12, 13
    srl x1, x10, x7
    ori x10, x10, 663
    sra x11, x2, x1
    srl x11, x13, x12
    and x10, x5, x7
    sll x3, x4, x7
    xori x8, x1, 643
    sra x5, x11, x12
    sra x4, x12, x2
    # --- VERIFY x3 ---
    lui x14, 0
    addi x14, x14, 0
    bne x3, x14, test_fail
    srli x6, x3, 24
    sub x5, x1, x13
    add x7, x13, x1
    add x10, x2, x4
    andi x4, x1, 608
    srl x1, x2, x9
    addi x10, x12, 387
    xor x12, x13, x3
    sltu x1, x13, x3
    sltu x9, x8, x9
    srl x9, x9, x12
    andi x12, x3, -1407
    srai x2, x9, 13
    andi x8, x10, 2045
    slt x11, x6, x4
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, 0
    bne x4, x14, test_fail
    xori x2, x12, 149
    xori x11, x7, 10
    xor x6, x9, x1
    or x5, x4, x13
    ori x3, x3, -2021
    addi x2, x13, 1452
    addi x8, x9, -1652
    sltu x13, x2, x5
    addi x10, x11, 202
    sltu x8, x4, x9
    and x13, x5, x4
    xor x6, x12, x5
    sll x11, x7, x9
    xor x6, x10, x7
    addi x12, x5, 221
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, -1089
    bne x11, x14, test_fail
    slt x10, x4, x7
    xor x9, x9, x11
    slt x1, x12, x1
    xor x13, x11, x7
    sra x3, x8, x13
    and x3, x12, x3
    sltu x5, x9, x11
    sltu x10, x12, x13
    xori x1, x13, -1773
    xori x13, x5, -338
    or x6, x13, x4
    srai x7, x1, 19
    sltu x2, x4, x10
    slli x6, x3, 24
    slt x10, x7, x11
    # --- VERIFY x1 ---
    lui x14, 0
    addi x14, x14, -1773
    bne x1, x14, test_fail
    xori x2, x8, 1767
    addi x8, x2, -1027
    sub x13, x7, x13
    xori x8, x13, 570
    sltu x1, x8, x9
    ori x7, x3, 1929
    and x1, x12, x9
    srl x6, x3, x3
    or x2, x9, x11
    addi x12, x11, -1269
    sra x9, x12, x7
    and x3, x2, x12
    xori x2, x3, 64
    ori x5, x2, 121
    addi x13, x7, -527
    # --- VERIFY x3 ---
    lui x14, 1048575
    addi x14, x14, 650
    bne x3, x14, test_fail
    sll x12, x5, x9
    or x7, x9, x2
    xor x7, x3, x2
    xor x6, x7, x4
    slli x10, x6, 0
    sub x4, x9, x1
    xor x7, x4, x12
    slt x5, x6, x2
    srli x5, x13, 30
    xor x13, x9, x2
    slli x12, x6, 23
    xori x8, x11, -1989
    srli x13, x12, 6
    sll x2, x1, x4
    sub x8, x13, x9
    # --- VERIFY x12 ---
    lui x14, 131072
    addi x14, x14, 0
    bne x12, x14, test_fail
    add x3, x1, x8
    addi x3, x3, 1313
    sub x10, x1, x11
    sll x4, x2, x7
    sll x2, x12, x9
    srli x8, x12, 12
    add x7, x4, x13
    xori x4, x6, -977
    add x9, x11, x7
    xori x1, x4, -27
    addi x11, x3, 509
    sltu x13, x10, x13
    and x13, x10, x11
    sll x1, x8, x2
    addi x3, x13, -673
    # --- VERIFY x13 ---
    lui x14, 2048
    addi x14, x14, -867
    bne x13, x14, test_fail
    sub x1, x12, x8
    or x2, x8, x13
    slt x11, x13, x1
    addi x8, x8, -1046
    sll x9, x7, x1
    or x7, x6, x5
    and x9, x6, x2
    add x13, x6, x5
    add x9, x11, x11
    srli x2, x1, 14
    srli x7, x5, 18
    slli x8, x11, 30
    andi x11, x8, 784
    srl x11, x7, x4
    slt x11, x3, x1
    # --- VERIFY x3 ---
    lui x14, 2048
    addi x14, x14, -1540
    bne x3, x14, test_fail
    or x2, x5, x4
    and x12, x13, x5
    sltu x6, x11, x2
    sll x5, x9, x5
    or x3, x13, x4
    srl x8, x13, x6
    sra x8, x3, x2
    and x9, x5, x11
    ori x12, x3, 530
    sll x5, x9, x8
    addi x2, x6, -1820
    slli x3, x9, 8
    slli x13, x9, 27
    srai x7, x5, 14
    srli x12, x13, 28
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, 0
    bne x13, x14, test_fail
    sltu x6, x2, x2
    sll x1, x13, x13
    srl x2, x2, x7
    sub x4, x4, x9
    sra x6, x12, x11
    andi x13, x4, 269
    xor x11, x9, x7
    srli x13, x7, 15
    and x7, x9, x13
    or x8, x1, x3
    andi x5, x12, 147
    srai x10, x8, 17
    xor x12, x12, x13
    srli x2, x9, 21
    xori x6, x11, 2018
    # --- VERIFY x10 ---
    lui x14, 0
    addi x14, x14, 0
    bne x10, x14, test_fail
    xor x8, x12, x11
    slli x10, x13, 8
    xor x2, x12, x12
    xori x3, x5, -946
    srli x8, x3, 11
    slt x9, x6, x9
    sll x11, x12, x6
    and x2, x10, x2
    ori x12, x5, -855
    srli x10, x5, 3
    sltu x7, x9, x3
    slli x12, x2, 13
    or x13, x11, x5
    andi x10, x10, 274
    addi x11, x13, -1873
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, -913
    bne x4, x14, test_fail
    add x8, x1, x10
    add x5, x7, x7
    srli x9, x13, 10
    srl x7, x6, x8
    srli x4, x4, 6
    sra x7, x8, x13
    sll x6, x1, x10
    srl x7, x3, x13
    xori x7, x8, -1430
    slli x3, x8, 5
    xor x10, x13, x3
    srl x5, x9, x1
    srl x3, x10, x3
    srai x11, x1, 30
    srai x7, x10, 28
    # --- VERIFY x5 ---
    lui x14, 0
    addi x14, x14, 0
    bne x5, x14, test_fail
    andi x12, x9, -1494
    sll x5, x12, x1
    xor x2, x4, x4
    addi x1, x9, 1494
    srai x8, x4, 2
    ori x4, x13, 1020
    and x8, x11, x9
    xor x8, x3, x6
    slli x8, x11, 31
    ori x1, x11, 680
    or x2, x4, x2
    slt x9, x12, x10
    ori x12, x10, -335
    srli x5, x3, 23
    sltu x11, x4, x12
    # --- VERIFY x1 ---
    lui x14, 0
    addi x14, x14, 680
    bne x1, x14, test_fail
    sra x3, x10, x5
    ori x3, x13, -535
    sll x10, x10, x11
    andi x12, x7, 1562
    sltu x7, x5, x5
    srai x9, x11, 23
    srli x6, x4, 21
    ori x8, x13, 495
    xori x6, x8, -1922
    slli x5, x2, 31
    sltu x3, x8, x11
    ori x1, x11, -1030
    and x13, x13, x1
    sra x2, x3, x10
    slt x5, x13, x7
    # --- VERIFY x6 ---
    lui x14, 0
    addi x14, x14, -1647
    bne x6, x14, test_fail
    slt x13, x6, x8
    and x1, x2, x4
    srli x6, x7, 19
    sub x9, x1, x2
    xor x4, x9, x10
    srai x1, x10, 20
    srli x8, x1, 15
    sltu x3, x11, x6
    srl x12, x5, x1
    andi x6, x5, -1346
    add x13, x12, x5
    slli x7, x2, 27
    sll x9, x11, x2
    srli x9, x7, 2
    sll x11, x9, x2
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 0
    bne x9, x14, test_fail
    sra x8, x1, x6
    sub x7, x9, x5
    xor x10, x7, x13
    addi x4, x2, 1641
    srl x3, x13, x8
    slli x1, x12, 0
    sltu x7, x8, x8
    add x4, x6, x3
    sltu x12, x4, x1
    add x4, x11, x12
    add x7, x5, x1
    sltu x11, x10, x3
    sra x13, x5, x12
    srl x11, x4, x8
    add x6, x10, x2
    # --- VERIFY x8 ---
    lui x14, 0
    addi x14, x14, 0
    bne x8, x14, test_fail
    add x5, x12, x8
    sub x10, x4, x10
    srli x9, x11, 10
    addi x9, x2, 1206
    sltu x10, x8, x6
    slli x7, x4, 0
    sra x11, x10, x12
    ori x9, x2, -745
    andi x5, x6, -891
    addi x11, x6, -597
    slt x11, x8, x11
    sll x10, x13, x1
    add x1, x9, x7
    sltu x8, x11, x8
    andi x13, x13, -1250
    # --- VERIFY x10 ---
    lui x14, 0
    addi x14, x14, 0
    bne x10, x14, test_fail
    addi x2, x3, -1005
    sltu x13, x10, x8
    andi x3, x12, -1076
    ori x8, x5, 1333
    or x10, x10, x10
    addi x8, x5, 980
    srai x2, x12, 7
    addi x13, x3, 1386
    sltu x11, x13, x13
    or x9, x11, x7
    sll x8, x12, x7
    slt x11, x3, x7
    srai x3, x7, 13
    sub x6, x6, x8
    or x8, x10, x7
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 0
    bne x7, x14, test_fail
    srai x10, x2, 28
    sltu x9, x4, x8
    srli x3, x12, 12
    srl x8, x7, x12
    sltu x6, x4, x9
    sltu x8, x11, x11
    slli x12, x3, 28
    xori x5, x5, -756
    slt x2, x7, x1
    sll x11, x4, x5
    sltu x7, x2, x5
    or x8, x11, x1
    slt x7, x13, x11
    slt x6, x1, x6
    sub x1, x6, x2
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, 1386
    bne x13, x14, test_fail
    srl x9, x11, x8
    srl x11, x2, x1
    xori x12, x1, -613
    sra x8, x11, x10
    add x6, x5, x6
    sub x9, x10, x13
    and x11, x13, x8
    srl x3, x12, x13
    addi x10, x4, -1225
    sll x9, x5, x10
    sra x2, x2, x10
    srl x9, x13, x3
    xori x12, x9, 1000
    slli x10, x6, 2
    srli x2, x13, 13
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, 0
    bne x4, x14, test_fail
    xor x1, x4, x10
    add x11, x4, x5
    andi x13, x10, 1435
    srai x5, x5, 22
    addi x4, x10, 1783
    xori x1, x5, 1036
    addi x7, x12, 77
    add x9, x5, x5
    srli x2, x2, 7
    srl x1, x7, x11
    srl x11, x6, x10
    ori x4, x12, -1351
    xori x12, x13, -1044
    sub x3, x12, x1
    srl x6, x10, x11
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, -2
    bne x9, x14, test_fail
    or x2, x13, x7
    srl x1, x10, x6
    sltu x7, x4, x8
    sra x12, x12, x8
    xor x12, x4, x5
    andi x5, x1, 228
    xori x11, x3, 592
    sll x1, x6, x4
    ori x7, x9, -625
    sltu x1, x9, x1
    andi x6, x9, 291
    sltu x8, x11, x1
    sra x1, x7, x4
    sra x2, x10, x5
    and x10, x11, x3
    # --- VERIFY x1 ---
    lui x14, 0
    addi x14, x14, -1
    bne x1, x14, test_fail
    xor x1, x7, x3
    sll x12, x12, x5
    sra x5, x6, x4
    srl x12, x7, x12
    sll x3, x9, x12
    slli x10, x1, 29
    sltu x3, x9, x8
    xor x5, x5, x1
    sra x12, x12, x8
    sra x13, x4, x3
    srli x10, x8, 0
    slt x3, x12, x12
    add x6, x4, x10
    sra x9, x9, x2
    addi x1, x11, 939
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, -1
    bne x7, x14, test_fail
    sll x10, x10, x2
    slli x1, x5, 16
    sll x9, x6, x2
    slt x10, x3, x4
    sltu x8, x10, x3
    xor x1, x5, x6
    srli x6, x9, 28
    addi x2, x7, -695
    sra x9, x2, x2
    sll x3, x2, x1
    srai x3, x13, 13
    xor x11, x1, x9
    sra x6, x12, x6
    srai x13, x7, 21
    add x4, x11, x10
    # --- VERIFY x1 ---
    lui x14, 0
    addi x14, x14, -1030
    bne x1, x14, test_fail
    and x11, x6, x13
    srli x3, x4, 22
    andi x6, x7, 918
    sltu x4, x2, x2
    sra x5, x7, x8
    or x10, x12, x12
    xor x8, x6, x12
    xori x2, x11, 1429
    andi x13, x4, -1935
    srai x1, x13, 0
    sll x3, x5, x13
    srli x13, x3, 29
    and x12, x6, x5
    addi x4, x1, -1113
    sll x6, x1, x7
    # --- VERIFY x12 ---
    lui x14, 0
    addi x14, x14, 918
    bne x12, x14, test_fail
    sltu x5, x1, x8
    add x5, x6, x12
    srli x13, x4, 17
    addi x2, x13, -1260
    srai x6, x4, 15
    xori x6, x5, -1809
    ori x5, x10, -1229
    xori x8, x4, -388
    sub x3, x2, x5
    srai x6, x9, 4
    addi x1, x4, -481
    or x6, x1, x3
    srli x1, x4, 25
    addi x5, x1, -373
    srl x6, x5, x9
    # --- VERIFY x11 ---
    lui x14, 8
    addi x14, x14, -1
    bne x11, x14, test_fail
    srli x9, x1, 17
    slli x9, x3, 5
    andi x4, x6, 951
    sll x6, x2, x12
    add x4, x10, x7
    srai x11, x8, 31
    srl x7, x10, x6
    xori x10, x6, -160
    sra x10, x11, x3
    or x4, x11, x6
    andi x7, x6, 455
    andi x9, x6, -392
    srli x13, x10, 10
    sub x6, x13, x13
    or x13, x8, x1
    # --- VERIFY x2 ---
    lui x14, 8
    addi x14, x14, -1261
    bne x2, x14, test_fail
    xor x8, x1, x3
    ori x13, x13, -993
    sra x4, x10, x11
    sra x6, x2, x9
    srai x9, x13, 31
    srli x12, x9, 24
    ori x5, x2, 2031
    or x6, x11, x8
    and x8, x6, x11
    sra x4, x6, x5
    slt x3, x7, x3
    andi x1, x5, -2033
    sltu x8, x8, x4
    addi x10, x4, 951
    srai x4, x10, 10
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, 0
    bne x4, x14, test_fail
    ori x13, x1, 319
    srli x4, x10, 15
    xori x12, x4, 143
    andi x12, x9, -477
    slli x11, x12, 8
    sub x3, x7, x9
    andi x13, x6, -391
    srai x11, x12, 29
    xor x13, x4, x11
    add x5, x9, x7
    xor x12, x7, x12
    srli x10, x2, 22
    sra x10, x5, x10
    srli x9, x6, 7
    sub x9, x2, x6
    # --- VERIFY x1 ---
    lui x14, 8
    addi x14, x14, -2033
    bne x1, x14, test_fail
    or x10, x10, x4
    sltu x2, x11, x10
    or x11, x5, x11
    slt x9, x13, x2
    xor x6, x6, x9
    sub x6, x9, x11
    and x4, x8, x6
    srli x3, x8, 10
    slt x4, x9, x1
    srli x4, x2, 23
    sltu x3, x1, x9
    xor x1, x13, x9
    sra x3, x2, x1
    slt x9, x8, x2
    addi x10, x2, 1573
    # --- VERIFY x2 ---
    lui x14, 0
    addi x14, x14, 0
    bne x2, x14, test_fail
    srli x10, x11, 18
    slli x1, x10, 18
    srli x4, x6, 10
    ori x10, x9, 1260
    xori x8, x10, 656
    slt x7, x12, x3
    add x3, x7, x6
    sub x7, x4, x11
    slli x3, x12, 21
    xori x11, x7, -763
    slt x13, x11, x5
    sra x4, x3, x2
    or x3, x7, x11
    slt x8, x5, x5
    srl x12, x10, x5
    # --- VERIFY x6 ---
    lui x14, 0
    addi x14, x14, 2
    bne x6, x14, test_fail
    slli x6, x1, 11
    sra x13, x5, x2
    ori x2, x8, 534
    xor x1, x3, x12
    sltu x10, x5, x9
    sub x11, x6, x12
    slt x1, x5, x2
    ori x13, x6, 1542
    xor x8, x5, x3
    sll x7, x3, x8
    slt x10, x5, x7
    xor x1, x3, x12
    or x1, x6, x10
    srai x3, x3, 30
    slli x2, x12, 12
    # --- VERIFY x8 ---
    lui x14, 0
    addi x14, x14, 762
    bne x8, x14, test_fail
    srai x1, x3, 24
    srai x5, x12, 6
    srai x6, x3, 30
    sub x8, x11, x2
    sub x3, x11, x5
    xori x10, x12, 30
    sra x4, x4, x6
    xori x7, x7, 1270
    srli x8, x7, 15
    srli x9, x7, 16
    slt x3, x3, x9
    srai x12, x11, 4
    andi x1, x9, 1375
    sub x3, x7, x2
    xor x11, x4, x3
    # --- VERIFY x5 ---
    lui x14, 0
    addi x14, x14, 0
    bne x5, x14, test_fail
    slt x9, x2, x8
    add x5, x13, x10
    andi x7, x1, -1875
    and x12, x8, x6
    sub x4, x6, x10
    sll x6, x8, x12
    xori x9, x2, -1297
    addi x6, x13, 126
    sra x13, x2, x9
    slli x2, x8, 29
    or x5, x9, x4
    add x7, x1, x1
    xori x4, x4, 708
    ori x4, x5, 874
    and x11, x5, x4
    # --- VERIFY x1 ---
    lui x14, 0
    addi x14, x14, 1024
    bne x1, x14, test_fail
    srl x8, x10, x3
    srl x1, x8, x1
    sub x13, x12, x6
    add x7, x7, x3
    slt x2, x7, x3
    srl x4, x11, x10
    add x6, x11, x12
    andi x3, x3, -296
    slt x4, x2, x9
    srai x7, x1, 23
    add x9, x9, x9
    sra x2, x9, x10
    addi x12, x6, -1427
    andi x10, x8, 1342
    sra x4, x1, x8
    # --- VERIFY x13 ---
    lui x14, 131074
    addi x14, x14, 380
    bne x13, x14, test_fail
    add x5, x8, x1
    sra x5, x13, x7
    sll x8, x4, x13
    slli x9, x2, 8
    ori x10, x3, -1693
    ori x4, x12, -679
    sub x2, x10, x9
    xor x8, x3, x9
    xor x1, x13, x1
    sltu x7, x8, x5
    add x6, x6, x3
    add x13, x8, x13
    sub x3, x6, x7
    xori x5, x12, -310
    sub x12, x6, x2
    # --- VERIFY x12 ---
    lui x14, 81923
    addi x14, x14, -564
    bne x12, x14, test_fail
    xori x3, x8, -155
    slt x8, x6, x2
    srl x13, x10, x8
    or x3, x10, x1
    slt x1, x6, x1
    sltu x3, x4, x13
    xori x1, x2, 1007
    xor x9, x12, x13
    xor x9, x6, x9
    slli x13, x8, 1
    srli x3, x4, 14
    sra x8, x13, x11
    andi x1, x1, 730
    ori x7, x12, -233
    andi x13, x12, 299
    # --- VERIFY x5 ---
    lui x14, 1048574
    addi x14, x14, -874
    bne x5, x14, test_fail
    or x13, x2, x13
    addi x9, x13, 1795
    sub x6, x2, x11
    srl x6, x2, x8
    sll x6, x8, x9
    srli x6, x9, 18
    andi x3, x6, -1743
    slt x2, x3, x3
    add x7, x11, x2
    sra x6, x3, x12
    andi x2, x2, 1434
    add x13, x12, x10
    srli x2, x7, 24
    or x12, x1, x1
    add x1, x6, x3
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, -163
    bne x4, x14, test_fail
    srli x13, x12, 20
    sltu x11, x13, x5
    slt x4, x10, x12
    srl x12, x13, x4
    srl x9, x5, x8
    xori x6, x8, 106
    slli x5, x13, 6
    xori x5, x8, -233
    slt x12, x7, x11
    andi x12, x12, 503
    srli x1, x7, 8
    addi x3, x5, -1872
    andi x12, x13, 218
    sltu x2, x9, x12
    or x6, x6, x7
    # --- VERIFY x12 ---
    lui x14, 0
    addi x14, x14, 0
    bne x12, x14, test_fail
    andi x12, x3, 1199
    and x9, x5, x8
    addi x3, x3, -1672
    srl x4, x7, x9
    andi x11, x3, 1671
    srli x3, x8, 27
    srai x4, x4, 0
    srli x12, x3, 10
    sra x6, x8, x9
    slli x1, x13, 7
    ori x3, x13, -79
    srli x8, x10, 0
    sltu x12, x9, x4
    sub x5, x5, x13
    sll x3, x6, x5
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, -17
    bne x7, x14, test_fail
    slt x13, x1, x7
    sra x4, x9, x3
    and x7, x9, x4
    addi x7, x7, 1630
    andi x13, x4, -245
    add x1, x12, x5
    sltu x5, x5, x4
    srli x9, x12, 17
    srai x11, x8, 12
    and x5, x13, x12
    slli x4, x1, 20
    add x5, x6, x13
    xori x1, x3, -936
    sltu x12, x9, x1
    slt x2, x8, x2
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 1630
    bne x7, x14, test_fail
    ori x1, x11, 358
    andi x8, x7, 105
    or x1, x7, x9
    sltu x7, x4, x10
    ori x11, x10, -1693
    srai x2, x13, 18
    ori x8, x12, -1314
    addi x8, x1, 1816
    and x1, x11, x6
    srl x6, x1, x2
    slli x13, x9, 27
    slt x6, x8, x5
    srli x11, x3, 10
    or x3, x4, x9
    srli x8, x10, 17
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 1
    bne x7, x14, test_fail
    sll x6, x9, x5
    sra x6, x2, x12
    add x6, x7, x12
    xori x1, x2, -1302
    srai x5, x5, 23
    slt x9, x11, x4
    or x1, x6, x4
    xor x2, x1, x13
    srl x5, x5, x8
    sra x12, x7, x4
    sra x6, x3, x4
    and x11, x6, x8
    slt x10, x4, x5
    srli x6, x2, 28
    ori x6, x9, -1896
    # --- VERIFY x6 ---
    lui x14, 0
    addi x14, x14, -1896
    bne x6, x14, test_fail
    and x9, x13, x6
    slt x3, x11, x13
    slli x5, x1, 7
    sub x7, x4, x3
    addi x9, x2, -1110
    slli x9, x1, 6
    sub x13, x1, x8
    xori x9, x9, -1883
    srl x13, x4, x13
    xori x3, x6, 1290
    slt x12, x7, x12
    slli x10, x1, 2
    xor x12, x4, x12
    or x5, x11, x12
    xor x13, x11, x13
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    and x13, x4, x1
    sltu x11, x5, x6
    srl x7, x8, x1
    sub x3, x9, x7
    slli x11, x13, 13
    xor x13, x8, x2
    xor x6, x9, x9
    slt x11, x4, x13
    and x3, x9, x1
    or x5, x1, x1
    or x4, x1, x8
    srai x12, x2, 5
    add x5, x3, x12
    slli x13, x12, 5
    addi x10, x10, 864
    # --- VERIFY x10 ---
    lui x14, 811008
    addi x14, x14, 872
    bne x10, x14, test_fail
    srli x13, x3, 9
    andi x13, x4, 1212
    slli x3, x1, 7
    or x9, x6, x3
    srai x4, x8, 3
    sll x1, x9, x12
    sltu x13, x13, x12
    add x11, x5, x6
    xor x2, x8, x4
    slli x8, x4, 3
    or x2, x11, x4
    add x13, x13, x5
    or x5, x1, x4
    and x13, x11, x1
    or x1, x6, x13
    # --- VERIFY x8 ---
    lui x14, 8
    addi x14, x14, -8
    bne x8, x14, test_fail
    ori x2, x4, 885
    or x8, x10, x12
    slt x2, x10, x8
    ori x5, x10, -210
    ori x12, x2, 1187
    srl x5, x6, x5
    andi x4, x7, -553
    sra x6, x4, x8
    srl x2, x9, x12
    slt x4, x12, x6
    srai x4, x6, 20
    and x2, x1, x9
    sub x1, x6, x7
    sub x2, x11, x8
    srai x6, x7, 13
    # --- VERIFY x13 ---
    lui x14, 524288
    addi x14, x14, 0
    bne x13, x14, test_fail
    srli x5, x11, 5
    xori x6, x11, -1268
    srl x5, x9, x9
    slt x4, x2, x7
    srai x9, x4, 8
    sll x8, x1, x3
    xor x2, x7, x3
    andi x7, x10, 1446
    sll x2, x2, x3
    sra x9, x13, x3
    ori x11, x4, -784
    srl x7, x5, x12
    xor x2, x7, x13
    sub x10, x3, x13
    add x6, x9, x13
    # --- VERIFY x6 ---
    lui x14, 0
    addi x14, x14, 0
    bne x6, x14, test_fail
    sltu x10, x9, x3
    slt x4, x13, x6
    addi x3, x2, -2
    add x3, x1, x11
    add x1, x4, x9
    xor x9, x9, x9
    srli x7, x1, 11
    add x8, x9, x2
    slli x6, x5, 25
    andi x12, x7, -1236
    add x10, x11, x8
    xori x1, x2, -1060
    or x7, x8, x11
    sub x9, x8, x8
    xor x12, x10, x11
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, -783
    bne x11, x14, test_fail
    srl x7, x5, x7
    slt x10, x2, x7
    srai x9, x9, 2
    add x1, x10, x2
    addi x9, x3, 1078
    srl x6, x5, x6
    or x11, x4, x1
    srl x3, x2, x5
    or x7, x2, x2
    slt x2, x1, x1
    xor x2, x6, x11
    xor x13, x5, x7
    slli x3, x13, 13
    sub x3, x10, x10
    sub x4, x3, x3
    # --- VERIFY x7 ---
    lui x14, 622592
    addi x14, x14, 32
    bne x7, x14, test_fail
    xor x11, x11, x4
    and x9, x11, x7
    xor x13, x4, x2
    xori x2, x12, -816
    sltu x11, x12, x6
    srai x12, x10, 0
    sra x5, x4, x12
    andi x11, x11, -930
    xori x4, x6, -643
    sra x10, x2, x12
    srl x3, x7, x13
    addi x4, x4, -1300
    sltu x3, x8, x13
    addi x11, x3, -728
    srli x4, x5, 17
    # --- VERIFY x3 ---
    lui x14, 0
    addi x14, x14, 0
    bne x3, x14, test_fail
    ori x1, x11, -214
    addi x5, x7, 1652
    slt x12, x12, x13
    andi x4, x11, -1126
    xor x7, x2, x6
    sub x5, x7, x6
    or x12, x2, x2
    sub x10, x6, x5
    andi x13, x4, 1838
    slt x10, x5, x8
    slli x3, x7, 31
    slli x8, x3, 6
    sltu x3, x9, x6
    sll x8, x3, x6
    srli x4, x10, 0
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, 1
    bne x4, x14, test_fail
    andi x3, x3, 1393
    or x9, x12, x4
    xori x4, x9, 500
    and x11, x11, x3
    addi x13, x9, 378
    andi x13, x12, 692
    xori x9, x8, 542
    andi x4, x6, -216
    or x1, x6, x9
    and x1, x11, x11
    add x8, x13, x12
    and x11, x4, x7
    addi x6, x4, 1898
    sltu x10, x5, x7
    srli x3, x8, 4
    # --- VERIFY x7 ---
    lui x14, 360448
    addi x14, x14, -976
    bne x7, x14, test_fail
    and x11, x1, x4
    sra x5, x4, x8
    srl x4, x1, x7
    xor x8, x10, x12
    srl x13, x13, x6
    srli x1, x12, 4
    slt x11, x7, x9
    slli x8, x4, 19
    add x7, x6, x1
    andi x3, x5, 1773
    add x8, x6, x8
    slli x13, x5, 25
    srl x11, x6, x1
    srl x2, x11, x1
    add x7, x4, x2
    # --- VERIFY x12 ---
    lui x14, 622592
    addi x14, x14, -720
    bne x12, x14, test_fail
    srai x5, x13, 8
    srli x3, x3, 6
    xor x1, x10, x8
    slli x5, x7, 10
    slli x12, x6, 8
    sub x8, x10, x2
    xori x2, x1, -361
    slt x11, x1, x10
    ori x6, x3, 1355
    sub x1, x8, x11
    srai x1, x10, 30
    sltu x8, x3, x12
    sll x5, x6, x9
    ori x10, x5, 747
    sll x2, x2, x3
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 543
    bne x9, x14, test_fail
    xori x13, x11, 833
    sub x6, x10, x3
    slt x4, x13, x2
    sra x11, x12, x8
    sub x12, x8, x12
    addi x8, x11, -848
    addi x7, x1, -162
    xor x1, x11, x6
    andi x8, x12, 772
    andi x12, x10, -1169
    srli x7, x12, 5
    sub x8, x5, x9
    srl x2, x13, x13
    sltu x5, x7, x7
    sra x10, x1, x3
    # --- VERIFY x2 ---
    lui x14, 0
    addi x14, x14, 832
    bne x2, x14, test_fail
    srli x4, x9, 22
    slt x13, x13, x6
    and x11, x9, x13
    slli x6, x13, 10
    ori x12, x7, -651
    xori x7, x12, -1246
    slli x9, x7, 1
    slt x6, x8, x13
    ori x7, x3, 1091
    sltu x13, x12, x10
    srli x11, x3, 1
    ori x1, x9, 155
    ori x9, x9, -117
    srai x8, x9, 11
    srl x8, x1, x8
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    sll x11, x8, x5
    andi x13, x8, 958
    xori x8, x10, 1141
    srai x12, x2, 24
    srli x7, x5, 0
    addi x8, x11, 521
    srl x6, x12, x9
    add x2, x9, x8
    srl x8, x12, x3
    xori x13, x12, 382
    sra x13, x11, x8
    xor x7, x12, x13
    slli x7, x12, 8
    sltu x6, x2, x1
    sltu x13, x8, x3
    # --- VERIFY x10 ---
    lui x14, 524355
    addi x14, x14, 2027
    bne x10, x14, test_fail
    add x9, x13, x12
    xori x4, x7, -1484
    ori x3, x12, 1364
    xor x12, x2, x13
    sll x2, x11, x2
    xor x10, x8, x3
    add x7, x3, x10
    sll x2, x10, x4
    slli x8, x4, 17
    srl x3, x8, x2
    or x7, x12, x8
    sra x11, x5, x11
    add x9, x11, x9
    srl x8, x11, x10
    sltu x12, x11, x5
    # --- VERIFY x12 ---
    lui x14, 0
    addi x14, x14, 0
    bne x12, x14, test_fail
    sub x12, x10, x5
    sltu x1, x12, x7
    add x10, x5, x10
    sub x11, x9, x2
    addi x11, x10, -1394
    xor x9, x5, x7
    slt x1, x12, x3
    slli x2, x8, 15
    add x12, x6, x10
    srai x11, x7, 24
    ori x7, x2, 1768
    srl x8, x10, x6
    sll x8, x10, x12
    sll x10, x13, x2
    sltu x3, x12, x11
    # --- VERIFY x10 ---
    lui x14, 0
    addi x14, x14, 0
    bne x10, x14, test_fail
    xor x8, x6, x3
    addi x8, x3, 1378
    or x11, x7, x2
    slli x1, x7, 22
    slli x8, x12, 6
    andi x9, x5, -109
    andi x4, x1, 1789
    xori x12, x11, -658
    slt x2, x9, x9
    sub x1, x8, x7
    slli x2, x8, 9
    slli x4, x8, 20
    addi x11, x9, -1659
    sll x3, x9, x13
    and x2, x7, x3
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 1768
    bne x7, x14, test_fail
    srli x12, x11, 6
    sll x6, x5, x6
    add x4, x11, x11
    andi x9, x6, 491
    srl x5, x11, x1
    xori x7, x3, -1786
    sll x7, x3, x5
    slli x1, x1, 22
    andi x12, x4, -800
    slt x5, x6, x4
    or x1, x10, x6
    srli x3, x12, 8
    slt x13, x12, x8
    srl x12, x11, x10
    andi x11, x5, 1965
    # --- VERIFY x5 ---
    lui x14, 0
    addi x14, x14, 0
    bne x5, x14, test_fail
    andi x12, x8, -1180
    sra x11, x12, x7
    srl x11, x1, x6
    sra x10, x4, x13
    add x12, x1, x2
    srai x11, x8, 7
    sra x10, x6, x6
    addi x1, x12, 1888
    sltu x11, x13, x5
    and x11, x6, x5
    or x8, x6, x9
    xori x9, x4, 1088
    xori x11, x12, 579
    sll x13, x10, x10
    srl x8, x11, x9
    # --- VERIFY x9 ---
    lui x14, 1048575
    addi x14, x14, 1866
    bne x9, x14, test_fail
    or x3, x10, x12
    sltu x2, x5, x8
    slli x12, x6, 23
    slt x10, x4, x3
    addi x2, x9, 361
    andi x9, x1, 1157
    add x3, x2, x11
    ori x2, x1, 1018
    srli x8, x3, 14
    xori x10, x9, -1410
    srl x4, x12, x13
    srli x1, x6, 22
    srli x7, x8, 23
    sub x4, x7, x10
    addi x7, x5, 1151
    # --- VERIFY x5 ---
    lui x14, 0
    addi x14, x14, 0
    bne x5, x14, test_fail
    andi x4, x3, 313
    sra x11, x12, x12
    srli x5, x9, 8
    addi x5, x12, -473
    slt x7, x3, x7
    xori x5, x4, 619
    add x11, x2, x13
    ori x9, x7, -1920
    or x13, x11, x1
    sll x9, x5, x3
    sltu x13, x4, x6
    slt x6, x2, x13
    addi x8, x1, -1946
    and x6, x9, x10
    xori x2, x13, 1941
    # --- VERIFY x2 ---
    lui x14, 0
    addi x14, x14, 1941
    bne x2, x14, test_fail
    srli x12, x6, 7
    or x9, x12, x11
    add x5, x10, x10
    srl x8, x6, x5
    xor x9, x1, x4
    sltu x7, x5, x2
    srl x1, x2, x6
    srli x1, x2, 18
    and x4, x3, x10
    sra x7, x9, x10
    addi x10, x12, -1869
    or x10, x7, x1
    add x12, x1, x3
    addi x5, x9, 557
    xor x11, x13, x10
    # --- VERIFY x8 ---
    lui x14, 0
    addi x14, x14, 9
    bne x8, x14, test_fail
    slli x2, x3, 16
    sub x12, x4, x13
    srl x5, x5, x1
    xor x9, x1, x7
    slli x12, x7, 13
    addi x12, x11, -470
    sltu x9, x12, x6
    xori x1, x3, -1231
    srl x1, x1, x1
    sra x8, x3, x2
    srli x4, x13, 26
    sra x11, x7, x8
    srai x8, x12, 13
    and x3, x10, x9
    sub x12, x5, x10
    # --- VERIFY x2 ---
    lui x14, 1027936
    addi x14, x14, 0
    bne x2, x14, test_fail
    add x1, x12, x2
    sll x2, x10, x10
    sltu x1, x9, x13
    srli x1, x11, 7
    addi x13, x12, -702
    slt x10, x7, x12
    sll x1, x12, x2
    sra x12, x9, x4
    or x9, x1, x8
    srli x1, x6, 10
    andi x5, x3, 961
    srai x9, x8, 3
    srli x2, x10, 14
    xori x5, x5, -1764
    xori x2, x11, 1896
    # --- VERIFY x6 ---
    lui x14, 617472
    addi x14, x14, 0
    bne x6, x14, test_fail
    xor x9, x9, x11
    srl x13, x3, x5
    addi x4, x7, 953
    slli x11, x3, 1
    srai x11, x10, 2
    xor x6, x1, x11
    sltu x1, x13, x10
    addi x13, x13, 1227
    srai x2, x7, 25
    addi x2, x13, -440
    sub x6, x13, x7
    or x10, x1, x6
    addi x2, x2, -1437
    andi x4, x4, -813
    andi x12, x8, -840
    # --- VERIFY x1 ---
    lui x14, 0
    addi x14, x14, 1
    bne x1, x14, test_fail
    and x10, x3, x9
    slt x9, x2, x11
    srl x11, x3, x9
    slli x12, x1, 10
    srli x4, x8, 9
    sll x7, x2, x6
    ori x11, x7, 128
    slli x4, x3, 28
    ori x10, x1, 500
    sra x6, x9, x9
    xor x11, x9, x9
    sra x13, x4, x9
    srai x3, x13, 28
    addi x10, x6, 770
    or x12, x5, x10
    # --- VERIFY x8 ---
    lui x14, 0
    addi x14, x14, -1
    bne x8, x14, test_fail
    or x1, x8, x4
    srl x1, x8, x4
    slli x12, x9, 17
    sra x5, x5, x8
    slli x10, x1, 10
    xori x6, x12, 1166
    ori x9, x4, 424
    ori x9, x10, -1435
    or x11, x12, x9
    xor x2, x3, x3
    xori x10, x6, 1839
    xori x9, x3, 1413
    or x5, x9, x7
    ori x11, x7, -1487
    addi x1, x2, -833
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 1413
    bne x9, x14, test_fail
    sub x9, x11, x6
    add x1, x2, x4
    sub x3, x6, x11
    ori x5, x2, -249
    andi x8, x10, -1651
    srli x5, x11, 1
    sub x2, x10, x4
    slt x9, x13, x6
    xor x9, x8, x10
    xor x9, x6, x5
    andi x11, x9, 846
    slt x2, x9, x8
    slli x1, x11, 20
    xor x7, x7, x7
    srl x1, x13, x7
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 0
    bne x7, x14, test_fail
    and x2, x1, x8
    ori x1, x8, 1738
    srli x1, x13, 26
    or x11, x1, x13
    srai x4, x7, 14
    ori x7, x13, 522
    sltu x5, x8, x2
    xori x13, x9, -1898
    add x5, x4, x1
    and x11, x11, x5
    or x5, x13, x5
    xor x2, x5, x3
    and x13, x10, x8
    add x2, x2, x2
    or x1, x10, x1
    # --- VERIFY x1 ---
    lui x14, 32
    addi x14, x14, 929
    bne x1, x14, test_fail
    xor x6, x4, x11
    ori x1, x2, -1161
    sltu x4, x11, x9
    or x2, x5, x6
    srl x5, x8, x11
    sll x8, x8, x4
    or x13, x10, x2
    sub x5, x13, x13
    slli x7, x9, 16
    srai x8, x11, 11
    srli x9, x2, 21
    sub x4, x3, x3
    xor x4, x13, x6
    sll x3, x6, x4
    xori x11, x11, -620
    # --- VERIFY x10 ---
    lui x14, 32
    addi x14, x14, 929
    bne x10, x14, test_fail
    srai x10, x8, 6
    srl x6, x3, x12
    andi x1, x13, -844
    ori x13, x1, -514
    addi x10, x12, -259
    srai x8, x13, 7
    add x12, x11, x11
    slli x3, x4, 6
    sra x2, x10, x9
    andi x12, x2, 232
    sltu x5, x12, x12
    ori x8, x13, 1985
    add x3, x1, x10
    or x13, x8, x1
    ori x2, x2, -1556
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 1024
    bne x9, x14, test_fail
    slli x5, x10, 23
    srli x11, x5, 4
    sltu x11, x2, x3
    srl x1, x4, x13
    sra x12, x8, x5
    slli x10, x5, 27
    xor x9, x10, x13
    sll x1, x10, x5
    srai x5, x13, 0
    sub x12, x5, x1
    srl x7, x6, x7
    sub x7, x11, x12
    and x12, x3, x1
    ori x1, x13, -1208
    slt x8, x7, x12
    # --- VERIFY x5 ---
    lui x14, 0
    addi x14, x14, -1
    bne x5, x14, test_fail
    or x9, x9, x1
    sll x12, x8, x7
    sll x6, x5, x2
    or x4, x8, x6
    slt x5, x3, x3
    ori x8, x2, -1606
    ori x8, x8, -799
    andi x11, x12, -1038
    add x1, x4, x11
    sltu x11, x12, x1
    ori x5, x3, -1630
    ori x1, x1, -1880
    or x13, x6, x9
    slt x4, x2, x4
    and x10, x10, x9
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 1
    bne x11, x14, test_fail
    ori x7, x6, 1557
    slli x4, x6, 30
    and x13, x13, x2
    sltu x5, x8, x13
    srl x9, x1, x8
    or x11, x11, x6
    slli x5, x7, 3
    slli x5, x11, 1
    slt x4, x12, x9
    or x10, x4, x1
    slli x13, x2, 25
    or x8, x5, x7
    sub x9, x3, x11
    sub x2, x11, x1
    and x2, x8, x6
    # --- VERIFY x6 ---
    lui x14, 917504
    addi x14, x14, 0
    bne x6, x14, test_fail
    sll x10, x12, x6
    sub x6, x4, x12
    xori x13, x5, 1203
    addi x10, x2, -237
    sll x9, x1, x8
    add x9, x12, x9
    srl x5, x9, x10
    xor x5, x7, x3
    andi x6, x1, 895
    or x12, x5, x9
    and x4, x5, x8
    add x10, x6, x12
    or x10, x2, x7
    srl x9, x12, x11
    xori x13, x11, -1281
    # --- VERIFY x5 ---
    lui x14, 393280
    addi x14, x14, -1656
    bne x5, x14, test_fail
    ori x1, x12, 457
    add x11, x10, x1
    srl x2, x7, x6
    and x2, x6, x7
    sub x9, x11, x12
    ori x12, x1, 280
    sltu x10, x9, x7
    xori x6, x13, 966
    xor x8, x8, x2
    xor x12, x9, x12
    xori x9, x7, 1058
    srai x13, x5, 31
    slt x3, x13, x1
    sub x5, x7, x6
    srai x1, x1, 31
    # --- VERIFY x4 ---
    lui x14, 393216
    addi x14, x14, 0
    bne x4, x14, test_fail
    srli x10, x11, 27
    slt x3, x9, x1
    srai x13, x13, 17
    add x9, x4, x9
    addi x6, x12, 381
    addi x12, x7, -2040
    add x9, x4, x12
    or x11, x4, x13
    slt x2, x8, x9
    sll x13, x2, x4
    andi x9, x11, 819
    sll x6, x8, x12
    addi x5, x9, 1330
    sltu x10, x10, x4
    addi x4, x8, -624
    # --- VERIFY x6 ---
    lui x14, 917504
    addi x14, x14, 0
    bne x6, x14, test_fail
    ori x11, x12, -631
    slt x12, x13, x3
    andi x11, x7, 1505
    sll x12, x9, x3
    ori x7, x11, -586
    ori x5, x2, -1627
    addi x4, x1, -1135
    sll x4, x7, x8
    sub x12, x12, x5
    srl x10, x13, x3
    slt x12, x2, x7
    xori x6, x1, -1226
    add x8, x9, x6
    slli x6, x7, 29
    xori x1, x6, -419
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 0
    bne x9, x14, test_fail
    xor x5, x8, x4
    or x12, x5, x3
    slli x8, x8, 25
    or x13, x5, x9
    addi x7, x6, -69
    slli x12, x1, 26
    or x6, x11, x5
    sltu x5, x11, x10
    and x13, x4, x9
    srli x1, x4, 18
    or x13, x4, x11
    addi x6, x8, 140
    add x11, x6, x3
    ori x11, x11, 1481
    xor x10, x4, x4
    # --- VERIFY x9 ---
    lui x14, 0
    addi x14, x14, 0
    bne x9, x14, test_fail
    ori x3, x2, 889
    addi x7, x1, 1908
    sra x7, x12, x12
    ori x12, x3, 990
    add x9, x13, x10
    add x3, x2, x12
    or x13, x10, x3
    xori x2, x3, 1350
    and x2, x4, x1
    srli x5, x12, 1
    srl x2, x13, x3
    and x9, x10, x11
    ori x10, x4, 1115
    ori x11, x7, -1137
    ori x6, x12, -747
    # --- VERIFY x4 ---
    lui x14, 899072
    addi x14, x14, 0
    bne x4, x14, test_fail
    add x12, x1, x2
    sltu x10, x3, x13
    srli x12, x8, 10
    srai x5, x2, 5
    addi x9, x6, 646
    ori x10, x13, 882
    ori x8, x11, 783
    add x8, x10, x11
    and x8, x12, x3
    sltu x11, x5, x5
    sll x1, x11, x11
    srai x3, x3, 31
    ori x6, x9, -1813
    sra x1, x8, x7
    srl x4, x13, x7
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, 1024
    bne x13, x14, test_fail
    and x10, x2, x6
    or x5, x4, x4
    srli x6, x13, 7
    sra x12, x4, x8
    andi x3, x3, 1229
    srl x10, x3, x7
    andi x8, x6, 257
    xori x4, x8, 1897
    sll x6, x5, x10
    add x1, x8, x2
    srai x12, x9, 4
    sra x1, x11, x11
    or x6, x13, x1
    xor x2, x13, x4
    sra x4, x3, x5
    # --- VERIFY x6 ---
    lui x14, 0
    addi x14, x14, 1024
    bne x6, x14, test_fail
    srai x7, x5, 24
    sub x4, x1, x4
    srl x7, x4, x1
    xor x5, x4, x13
    xori x8, x8, 185
    srai x12, x10, 21
    ori x3, x12, -54
    srai x10, x9, 28
    srli x4, x7, 3
    sll x10, x10, x2
    sll x7, x1, x9
    sltu x2, x5, x5
    srli x2, x11, 4
    ori x9, x10, -273
    sll x2, x8, x6
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    addi x8, x1, -1701
    sra x11, x11, x3
    xor x4, x8, x13
    andi x13, x2, 1682
    sltu x7, x9, x7
    sra x13, x3, x10
    and x9, x11, x13
    add x12, x11, x11
    and x7, x3, x7
    sltu x12, x5, x11
    and x9, x2, x6
    addi x8, x7, 732
    and x10, x6, x12
    sub x11, x11, x10
    slt x4, x4, x6
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, -54
    bne x13, x14, test_fail
    add x12, x3, x7
    srli x8, x9, 15
    slli x2, x13, 22
    sll x9, x3, x9
    srai x9, x12, 4
    sub x9, x11, x6
    xor x12, x2, x11
    sra x3, x9, x4
    slt x10, x11, x6
    xori x9, x5, 797
    sltu x6, x1, x4
    srl x12, x3, x8
    sub x1, x8, x9
    xor x13, x8, x5
    sltu x13, x10, x1
    # --- VERIFY x12 ---
    lui x14, 0
    addi x14, x14, -512
    bne x12, x14, test_fail
    sll x2, x11, x9
    andi x1, x3, -121
    or x10, x13, x13
    srli x9, x3, 31
    sll x7, x13, x3
    sub x2, x9, x7
    srli x4, x3, 2
    srl x12, x3, x4
    andi x2, x3, 1528
    srli x5, x5, 24
    srli x9, x10, 22
    slt x6, x5, x4
    srl x13, x11, x10
    slli x13, x12, 13
    sra x6, x4, x4
    # --- VERIFY x2 ---
    lui x14, 0
    addi x14, x14, 1024
    bne x2, x14, test_fail
    or x9, x5, x7
    slt x6, x5, x3
    srl x6, x5, x9
    ori x2, x8, 650
    sra x6, x8, x4
    andi x12, x13, 1898
    sra x10, x7, x9
    srl x2, x4, x9
    sra x5, x8, x5
    srai x6, x10, 21
    slli x1, x12, 30
    add x8, x6, x4
    slt x5, x10, x9
    sub x4, x2, x5
    sll x10, x10, x3
    # --- VERIFY x12 ---
    lui x14, 0
    addi x14, x14, 0
    bne x12, x14, test_fail
    add x12, x7, x9
    slli x5, x3, 30
    slli x11, x13, 1
    sra x9, x11, x1
    or x8, x11, x12
    slt x7, x10, x9
    or x2, x7, x1
    srli x3, x12, 15
    sll x13, x7, x7
    slli x11, x13, 9
    sub x12, x9, x1
    ori x1, x5, -915
    or x12, x11, x13
    sltu x3, x6, x5
    andi x5, x5, -1288
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    xori x3, x3, 1141
    or x13, x1, x5
    sub x1, x10, x10
    srl x3, x7, x1
    addi x2, x5, 1373
    xor x5, x4, x4
    add x4, x12, x3
    xor x12, x8, x6
    srl x4, x11, x11
    sltu x2, x9, x10
    addi x3, x3, 669
    sub x2, x4, x13
    andi x2, x7, 2044
    xori x7, x9, -1940
    srl x6, x3, x10
    # --- VERIFY x2 ---
    lui x14, 0
    addi x14, x14, 0
    bne x2, x14, test_fail
    sra x4, x3, x9
    sltu x5, x11, x4
    srai x10, x7, 13
    add x1, x10, x12
    sltu x3, x1, x1
    sll x12, x8, x3
    andi x13, x5, -1326
    srl x3, x3, x4
    sub x1, x2, x11
    sub x11, x12, x1
    slt x9, x10, x5
    srai x5, x10, 4
    srl x13, x12, x1
    xor x12, x1, x11
    sub x2, x6, x8
    # --- VERIFY x7 ---
    lui x14, 2048
    addi x14, x14, -1940
    bne x7, x14, test_fail
    ori x8, x6, -922
    andi x9, x10, 1635
    sll x9, x9, x11
    slli x8, x7, 16
    xori x2, x11, 1259
    and x3, x12, x7
    srl x5, x10, x6
    sll x10, x9, x8
    slli x2, x10, 11
    and x9, x5, x9
    addi x5, x8, 802
    and x1, x2, x7
    add x6, x13, x11
    slt x5, x8, x5
    add x10, x4, x3
    # --- VERIFY x13 ---
    lui x14, 1046528
    addi x14, x14, 2
    bne x13, x14, test_fail
    add x3, x5, x10
    xori x11, x7, -890
    srl x3, x7, x7
    slt x4, x9, x1
    srli x5, x11, 10
    srl x3, x13, x2
    srai x6, x3, 30
    srl x9, x6, x10
    slt x13, x4, x2
    sll x6, x10, x11
    xori x9, x3, 47
    addi x1, x11, -1656
    srai x10, x8, 16
    xori x12, x12, 1034
    or x12, x9, x7
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, 1
    bne x4, x14, test_fail
    sra x12, x6, x2
    srai x10, x7, 12
    srl x11, x7, x1
    ori x11, x7, -1359
    xori x5, x10, -1171
    addi x12, x13, -574
    andi x4, x11, -651
    ori x12, x2, 1425
    and x3, x3, x11
    srai x12, x8, 19
    xori x12, x10, 1007
    addi x9, x11, 282
    srl x11, x13, x11
    slli x8, x8, 18
    and x6, x9, x1
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, 1
    bne x13, x14, test_fail
    sra x12, x6, x4
    sll x10, x9, x12
    slt x6, x12, x10
    slli x1, x2, 18
    add x7, x7, x2
    and x7, x5, x9
    sll x12, x6, x3
    slli x8, x5, 9
    add x2, x6, x2
    andi x8, x3, -1493
    slli x3, x8, 14
    add x5, x4, x11
    and x11, x2, x10
    and x4, x4, x2
    xori x8, x5, 610
    # --- VERIFY x8 ---
    lui x14, 0
    addi x14, x14, -1513
    bne x8, x14, test_fail
    or x11, x7, x3
    xor x5, x2, x1
    sub x7, x5, x4
    addi x7, x13, -1501
    add x3, x1, x4
    and x5, x7, x3
    sltu x5, x4, x13
    sltu x9, x9, x11
    xori x13, x11, 1218
    addi x6, x13, 202
    addi x8, x7, -897
    sll x1, x8, x8
    addi x4, x6, 1721
    sub x11, x3, x12
    sub x3, x5, x9
    # --- VERIFY x11 ---
    lui x14, 525510
    addi x14, x14, 0
    bne x11, x14, test_fail
    srli x10, x12, 23
    sll x10, x8, x10
    slli x3, x5, 20
    sub x5, x13, x7
    addi x5, x6, 1309
    andi x8, x2, 746
    ori x8, x3, -733
    srli x4, x8, 2
    addi x4, x5, -1512
    and x8, x13, x2
    andi x10, x5, -568
    or x10, x9, x9
    addi x2, x1, 1142
    add x9, x6, x4
    sra x12, x6, x9
    # --- VERIFY x1 ---
    lui x14, 1048571
    addi x14, x14, 1304
    bne x1, x14, test_fail
    sltu x3, x6, x2
    sra x3, x4, x7
    sltu x10, x4, x3
    slli x2, x12, 19
    xori x3, x4, 526
    add x8, x8, x3
    sltu x7, x10, x13
    add x9, x10, x8
    xori x9, x9, -1708
    sltu x6, x11, x9
    srai x1, x12, 17
    sub x7, x3, x13
    ori x10, x9, 580
    slli x13, x4, 8
    srai x5, x7, 14
    # --- VERIFY x11 ---
    lui x14, 525510
    addi x14, x14, 0
    bne x11, x14, test_fail
    sra x9, x2, x4
    addi x10, x9, 1884
    sltu x2, x2, x11
    srli x4, x9, 4
    slli x2, x9, 23
    srli x2, x3, 10
    xori x9, x11, -540
    slt x5, x12, x7
    srli x12, x9, 30
    xori x3, x1, 1391
    sra x6, x7, x6
    sll x2, x7, x11
    srai x6, x3, 19
    sltu x2, x5, x11
    andi x5, x5, 611
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 497
    bne x7, x14, test_fail
    ori x9, x5, -178
    sll x13, x8, x5
    sub x13, x12, x7
    and x1, x1, x8
    and x4, x2, x9
    add x6, x9, x13
    srli x7, x3, 31
    andi x8, x6, -975
    and x10, x5, x3
    srl x10, x12, x5
    srai x4, x13, 6
    and x9, x3, x13
    srai x11, x7, 22
    add x13, x7, x5
    and x7, x13, x1
    # --- VERIFY x4 ---
    lui x14, 0
    addi x14, x14, -8
    bne x4, x14, test_fail
    slli x6, x7, 9
    srl x3, x6, x13
    or x6, x2, x1
    xor x2, x10, x12
    andi x4, x1, 668
    xori x11, x4, -774
    slli x3, x11, 27
    sltu x11, x10, x10
    xor x9, x6, x10
    ori x4, x3, 842
    xori x8, x13, 12
    srli x2, x9, 13
    xori x11, x12, -367
    ori x9, x3, 1447
    slt x9, x7, x6
    # --- VERIFY x12 ---
    lui x14, 0
    addi x14, x14, 1
    bne x12, x14, test_fail
    sll x6, x6, x2
    srai x10, x9, 16
    srli x10, x12, 23
    sra x7, x5, x3
    srli x13, x9, 0
    xor x11, x5, x8
    xori x1, x4, 1912
    addi x9, x5, 1385
    srli x8, x2, 10
    srai x7, x3, 11
    andi x2, x13, 1363
    xori x8, x6, 352
    xor x9, x2, x4
    sra x11, x12, x6
    sub x2, x8, x2
    # --- VERIFY x3 ---
    lui x14, 851968
    addi x14, x14, 0
    bne x3, x14, test_fail
    sll x6, x13, x10
    andi x2, x11, 621
    srl x1, x6, x5
    addi x9, x3, -503
    or x11, x9, x4
    and x9, x2, x1
    srai x3, x11, 3
    sub x13, x5, x3
    sll x2, x2, x10
    slli x12, x4, 31
    sra x2, x5, x11
    add x13, x3, x7
    slli x9, x13, 20
    sra x5, x13, x7
    slli x7, x9, 6
    # --- VERIFY x8 ---
    lui x14, 4887
    addi x14, x14, -1436
    bne x8, x14, test_fail
    srl x5, x13, x5
    slli x2, x9, 13
    srai x3, x8, 2
    srli x10, x7, 25
    srai x12, x11, 30
    and x8, x7, x5
    ori x10, x4, -147
    slli x4, x11, 7
    srai x2, x10, 27
    srli x4, x9, 13
    or x7, x13, x4
    xor x9, x3, x4
    and x2, x2, x11
    slt x8, x1, x9
    and x5, x7, x5
    # --- VERIFY x13 ---
    lui x14, 1032096
    addi x14, x14, -23
    bne x13, x14, test_fail
    or x10, x13, x5
    andi x10, x5, -1940
    srl x7, x9, x12
    srli x2, x7, 12
    sra x5, x2, x11
    or x12, x13, x9
    sltu x3, x1, x6
    srli x11, x9, 29
    sll x7, x5, x2
    sll x7, x13, x7
    srai x6, x9, 21
    add x1, x2, x4
    xori x3, x5, -329
    sltu x10, x7, x5
    slli x11, x7, 0
    # --- VERIFY x6 ---
    lui x14, 0
    addi x14, x14, 2
    bne x6, x14, test_fail
    addi x6, x7, 110
    sltu x12, x9, x4
    slt x3, x13, x6
    or x5, x9, x10
    srli x7, x6, 29
    xori x10, x12, -1346
    addi x2, x7, 877
    addi x10, x7, 958
    sub x8, x7, x5
    srli x10, x1, 0
    xor x8, x5, x7
    sra x2, x8, x3
    srl x10, x3, x12
    sll x13, x2, x2
    sra x12, x7, x2
    # --- VERIFY x7 ---
    lui x14, 0
    addi x14, x14, 7
    bne x7, x14, test_fail
    or x5, x13, x3
    xor x7, x5, x1
    slli x6, x12, 16
    sll x12, x8, x5
    srli x3, x13, 21
    srai x11, x8, 25
    slli x4, x12, 19
    add x8, x12, x13
    xori x13, x9, -32
    sra x9, x3, x8
    xori x4, x5, -23
    or x2, x13, x13
    sub x4, x9, x11
    sra x6, x5, x8
    and x12, x7, x7
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, 0
    bne x11, x14, test_fail
    slt x7, x7, x13
    or x6, x8, x6
    sll x12, x5, x8
    sub x6, x12, x4
    andi x10, x11, 1632
    slli x9, x2, 13
    srl x11, x7, x13
    sra x5, x12, x12
    srli x8, x13, 5
    slt x10, x5, x12
    srli x3, x4, 20
    sll x1, x9, x9
    sll x11, x3, x12
    srai x3, x10, 1
    andi x5, x2, 1400
    # --- VERIFY x10 ---
    lui x14, 0
    addi x14, x14, 0
    bne x10, x14, test_fail
    sra x12, x7, x8
    xori x9, x8, -446
    add x7, x7, x3
    xor x10, x9, x8
    ori x7, x13, 1203
    addi x3, x13, -1248
    sra x8, x10, x11
    sub x12, x6, x6
    andi x13, x5, -907
    slli x1, x8, 14
    sra x5, x3, x4
    slt x7, x12, x4
    sltu x3, x9, x7
    sltu x13, x9, x10
    sra x9, x7, x12
    # --- VERIFY x8 ---
    lui x14, 0
    addi x14, x14, -446
    bne x8, x14, test_fail
    andi x11, x11, -565
    sub x8, x4, x13
    xori x8, x1, 579
    add x1, x9, x5
    or x2, x7, x8
    slli x10, x9, 18
    andi x10, x8, 2047
    add x12, x1, x10
    sll x7, x11, x7
    srli x9, x9, 6
    slt x4, x8, x4
    srl x4, x13, x7
    and x13, x10, x3
    sltu x13, x13, x13
    sra x3, x4, x8
    # --- VERIFY x13 ---
    lui x14, 0
    addi x14, x14, 0
    bne x13, x14, test_fail
    slli x10, x13, 11
    ori x11, x3, -984
    add x10, x10, x13
    sll x10, x5, x10
    add x13, x13, x11
    or x5, x1, x5
    add x5, x9, x3
    or x3, x9, x5
    xori x3, x11, 2044
    slli x10, x13, 7
    srl x6, x2, x2
    ori x1, x11, 337
    andi x5, x8, -1342
    ori x7, x4, 1668
    sltu x2, x4, x13
    # --- VERIFY x3 ---
    lui x14, 0
    addi x14, x14, -1068
    bne x3, x14, test_fail
    xori x6, x6, 1770
    slli x12, x10, 18
    xori x7, x11, 657
    slli x4, x10, 19
    srl x13, x2, x6
    andi x11, x3, -393
    ori x3, x2, -810
    sub x13, x1, x5
    srli x10, x10, 10
    srli x1, x13, 28
    or x11, x2, x9
    sra x5, x5, x1
    andi x3, x1, -504
    xori x9, x6, 495
    slt x12, x6, x10
    # --- VERIFY x9 ---
    lui x14, 130849
    addi x14, x14, 1869
    bne x9, x14, test_fail
    andi x5, x3, 1391
    or x5, x13, x1
    slli x5, x10, 26
    and x8, x9, x7
    or x4, x1, x2
    sltu x8, x9, x6
    or x9, x5, x10
    sll x12, x11, x5
    srai x10, x2, 3
    sltu x2, x3, x8
    srl x8, x7, x7
    and x8, x1, x7
    addi x13, x12, -215
    addi x8, x7, -721
    and x9, x1, x12
    # --- VERIFY x3 ---
    lui x14, 0
    addi x14, x14, 0
    bne x3, x14, test_fail
    sll x8, x10, x2
    and x2, x13, x7
    xor x11, x10, x5
    and x1, x13, x4
    sra x6, x3, x6
    sll x4, x4, x1
    or x9, x11, x5
    addi x6, x11, -1420
    andi x9, x9, -343
    srl x2, x10, x2
    sub x3, x6, x8
    andi x11, x1, -637
    andi x8, x7, 1018
    and x5, x9, x10
    and x8, x7, x9
    # --- VERIFY x5 ---
    lui x14, 0
    addi x14, x14, 0
    bne x5, x14, test_fail
    and x7, x13, x13
    addi x2, x3, -1520
    add x13, x7, x5
    xor x3, x2, x5
    xori x8, x13, -1911
    sltu x2, x4, x4
    srai x3, x6, 1
    xori x11, x2, -821
    xor x13, x5, x9
    andi x1, x1, -1287
    xori x10, x10, -983
    slt x9, x2, x3
    or x13, x12, x13
    sltu x8, x5, x7
    sub x3, x10, x12
    # --- VERIFY x11 ---
    lui x14, 0
    addi x14, x14, -821
    bne x11, x14, test_fail
    srl x4, x9, x12
    slt x11, x2, x8
    ori x12, x1, -1322
    slli x4, x3, 17
    srai x6, x5, 17
    sll x8, x10, x2
    xor x10, x2, x6
    sub x13, x13, x12
    sll x10, x7, x3
    sub x11, x10, x10
    slt x9, x1, x5
    sll x7, x2, x8
    addi x13, x5, 1231
    sra x10, x5, x13
    srai x6, x11, 12
    # --- VERIFY x4 ---
    lui x14, 1017088
    addi x14, x14, 0
    bne x4, x14, test_fail
    andi x5, x12, -1157
    ori x2, x10, 1449
    andi x8, x6, -400
    srli x3, x11, 31
    sltu x13, x6, x10
test_pass:
    li x1, 1
    ebreak
test_fail:
    li x1, 2
    ebreak
