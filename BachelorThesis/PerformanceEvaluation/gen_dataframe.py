pre1f = open('time_nano1pre.txt', 'r', encoding='utf-8')
pre2f = open('time_nano2pre.txt', 'r', encoding='utf-8')
pre3f = open('time_nano3pre.txt', 'r', encoding='utf-8')
pre4fix = open('time_nano1prefix.txt', 'r', encoding='utf-8')
post1f = open('time_nano1post.txt', 'r', encoding='utf-8')
post2f = open('time_nano2post.txt', 'r', encoding='utf-8')
post3f = open('time_nano3post.txt', 'r', encoding='utf-8')
post4f = open('time_nano4post.txt', 'r', encoding='utf-8')
post1ft = open('time_nano1posttcp.txt', 'r', encoding='utf-8')
post2ft = open('time_nano2posttcp.txt', 'r', encoding='utf-8')
post3ft = open('time_nano3posttcp.txt', 'r', encoding='utf-8')
reqcf = open('request_counter.txt', 'r', encoding='utf-8')
# pre1f = open('time_nano1pre.txt', 'r', encoding='utf-8')

pre1fr = pre1f.readlines()
pre2fr = pre2f.readlines()
pre3fr = pre3f.readlines()
pre4fixr = pre4fix.readlines()
post1fr = post1f.readlines()
post2fr = post2f.readlines()
post3fr = post3f.readlines()
post4fr = post4f.readlines()
post1ftr = post1ft.readlines()
post2ftr = post2ft.readlines()
post3ftr = post3ft.readlines()
reqcfr = reqcf.readlines()

print("Length:", len(pre1fr), len(pre2fr), len(pre3fr), len(post1fr), len(post2fr), len(post3fr), len(reqcfr))
output = [[] for _ in range(len(pre1fr))]

request_id = 1
current_test = -1
last_reqc = 0
for i in range(len(pre1fr)):
    if pre1fr[i].startswith('TEST'):
        current_test = pre1fr[i][5:-2]
        # print(current_test)
        request_id = 1
        last_reqc = 0
        continue
    output[i].append(current_test)
    output[i].append(request_id)
    request_id += 1
    output[i].append(pre1fr[i][10:-1])
    output[i].append(pre2fr[i][10:-1])
    output[i].append(pre3fr[i][10:-1])
    output[i].append(pre4fixr[i][10:-1])
    output[i].append(post1fr[i][10:-1])
    output[i].append(post2fr[i][10:-1])
    output[i].append(post3fr[i][10:-1])
    output[i].append(post4fr[i][10:-1])
    output[i].append(post1ftr[i][10:-1])
    output[i].append(post2ftr[i][10:-1])
    output[i].append(post3ftr[i][10:-1])
    # print("!", pre1fr[i][10:-1])
    reqc = int(reqcfr[i][15:-1])
    output[i].append(reqc - last_reqc)
    last_reqc = reqc

print(output)

with open('output.csv', 'w', encoding='utf-8') as file:
    file.write("test_id,query_id,pre1_ns,pre2_ns,pre3_ns,pre1_fix_ns,post1_ipc_ns,post2_ipc_ns,post3_ipc_ns,post4_ipc_ns,post1_tcp_ns,post2_tcp_ns,post3_tcp_ns,request_counter\n")
    for i in range(len(output)):
        if output[i]:
            file.write(','.join(map(str, output[i])) + '\n')
