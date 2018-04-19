python3 << EOF
import vim
class VerilogParse:
    def __init__(self):
        self.buffer = vim.current.buffer
        #self.buffer = open('up_ctrl.v', 'r', encoding='utf-8').readlines()
        self.port = []      # 存放端口列表
        self.module_para = []
        self.content = []

        self.inst = ''

        self.dict = {}

    def paser_port(self, content):
        for i in content:
            line = i.strip()
            if line.find('=') != -1:
                line = line[:line.find('=')]  # 去掉逗号后面所有字符

            if line.find(',') != -1:
                line = line[:line.find(',')]     # 去掉逗号后面所有字符
            if line.find('//') != -1:
                line = line[:line.find('//')]    # 如果是最后一行端口声明，去掉注释
            # print(line)
            if line.find('always') != -1:
                break
            else:
                if line.find('input') == 0 or line.find('output') == 0 or line.find('inout') == 0:
                    if line.find('input') == 0:
                        self.dict['port_type'] = 'input'        # 获得端口类型， 删除input字符串
                        line = line.replace('input', '').strip()
                    elif line.find('output') == 0:
                        self.dict['port_type'] = 'output'  # 获得端口类型， 删除output字符串
                        line = line.replace('output', '').strip()
                    elif line.find('inout') == 0:
                        self.dict['port_type'] = 'inout'  # 获得端口类型， 删除inout字符串
                        line = line.replace('inout', '').strip()

                    if line.find('reg') == 0:
                        self.dict['vari_type'] = 'reg'
                        line = line.replace('reg', '').strip()
                    else:
                        self.dict['vari_type'] = 'wire'
                        line = line.replace('wire', '').strip()

                    if line.find('[') == 0:
                        self.dict['width'] = line[line.find('[') + 1:line.find(']')]

                        line = line[line.find(']') + 1:].strip()
                        self.dict['name'] = line
                    else:
                        self.dict['width'] = '1'
                        self.dict['name'] = line

                    dict = self.dict.copy()
                    self.port.append(dict)
        return self.port

    """
    删除文件里的所有注释代码
    """
    def delete_all_comment(self):
        comment_flag = 0
        for line in self.buffer:
            line = line.strip()

            if line.find('/*') == 0 and line.find('*/') > 2:
                 continue
            elif line.find('/*') == 0:
                comment_flag = 1
                continue
            elif line.find('*/') != -1:
                comment_flag = 0
                continue

            if comment_flag == 0:
                if line.find('//') != -1:
                    line = line[:line.find('//')]
                    line = line.rstrip()
                if line:
                    self.content.append(line)
        return self.content

    def parse_module_name(self, content):
        for line in content:
            if line.find('module') != -1:
                module_name = line.split(' ')[1]
                break

        return module_name

    def parse_module_para(self):
        self.delete_all_comment()
        para_dict = {}
        for line in self.content:
            if line.find('input') != -1 or line.find('output') != -1 or line.find('inout') != -1 :
                break
            elif line.find('parameter') == 0:
                line = line.replace('parameter', '').strip()
                para_dict['para_name'] = line[:line.find('=')].strip()
                para_dict['para_value'] = line[line.find('=')+1:].replace(',', '').strip().rstrip()

                dict = para_dict.copy()
                self.module_para.append(dict)

        return self.module_para

    def find_sub_module(self):
        pass

    def instance_module(self):
        self.delete_all_comment()

        module_name = self.parse_module_name(self.content)
        port = self.paser_port(self.content)
        module_para = self.parse_module_para()

        max_length = 0
        for p in port:
            if max_length < len(p['name']):
                max_length = len(p['name'])
        for p in module_para:
            if max_length < len(p['para_name']):
                max_length = len(p['para_name'])
        max_length = (max_length//4+1)*4  # tab 可以对齐

        if module_para:
            cnt = 0
            self.inst = module_name + ' #\n(\n'
            for ele in module_para:
                if cnt + 1 == len(module_para):  # 最后一个参数
                    self.inst += '    .' + ele['para_name'] + (max_length - len(ele['para_name'])) * ' ' + '(' + '  ' + \
                                 ele['para_value'] + (max_length - len(ele['para_value'])) * ' ' + ')'
                    self.inst += '\n)\n' + module_name + 'Ex01\n(\n'
                else:
                    self.inst += '    .' + ele['para_name'] + (max_length - len(ele['para_name']))*' ' + '(' + '  ' + ele['para_value'] +  (max_length-len(ele['para_value']))*' ' + '),\n'
                    cnt += 1
        else:
            self.inst = module_name + ' ' + module_name + 'Ex01' + '\n(\n'

        cnt = 0

        for ele in port:
            if cnt+1 == len(port):
                self.inst += '    .' + ele['name'] + (max_length-len(ele['name']))*' ' + '(' + '  ' + ele['name'] + (max_length-len(ele['name'])+4)*' ' + ')'
                self.inst += '\n);'
            else:
                self.inst += '    .' + ele['name'] + (max_length-len(ele['name']))*' ' + '(' + '  ' + ele['name'] +  (max_length-len(ele['name'])+4)*' ' + '),\n'
            cnt += 1

        return self.inst
    # def align_instance(self):
    #     p = re.compile(r'\.\w+\s*\(')
    #
    #     for line in self.content:
    #
    #     max_left = 0
    #     for line in align:
    #         t = line.split('(')
    #         if max_left < len(t[0]):
    #             max_left = len(t[0])
    #
    #     # for line in l:
    #     for i in range(len(align)):
    #         t = align[i].split('(')
    #         t[0] = t[0].ljust(max_left+10)
    #         t[1] = '(  '+t[1]
    #         align[i] = ''.join(t)
    #
    #     for i in range(len(align)):
    #         t = align[i].split(')')
    #         t[0] = t[0].ljust((max_left+10)*2)
    #         t[1] = ')'+t[1]
    #         align[i] = ''.join(t)
    #
    #     for line in align:
    #         print(line)
    #         pass

    def paste(self):
        txt = self.instance_module()
        vim.command('let @*= "%s"' % txt)
        return txt
EOF

let s:com = "py3"
function! instance#generate()
    "python3 VerilogParse().paste()
    exec s:com 'VerilogParse().paste()'
    echo @*
endfunction
