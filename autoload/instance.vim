python3 << EOF
import vim
import os
class VerilogParse:
    def __init__(self):
        # self.buffer = vim.current.buffer
        # self.buffer = open('location_module.v', 'r', encoding='utf-8').readlines()
        self.buffer = open('pos_fifo.v', 'r', encoding='utf-8').readlines()
        self.port = []      # 存放端口列表
        self.module_para = []

        self.inst = ''

        self.dict = {}

        self.content = self.delete_all_comment()

    def paser_port(self, content):
        """
        找到verilog里的所有端口
        :param content:
        :return:
        """
        for i in content:
            line = i.strip()
            if line.find('=') != -1:
                line = line[:line.find('=')]  # 去掉逗号后面所有字符

            if line.find(',') != -1:
                line = line[:line.find(',')]     # 去掉逗号后面所有字符
            if line.find(';') != -1:
                line = line[:line.find(';')]  # 去掉逗号后面所有字符
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

    def delete_all_comment(self):
        """
        删除文件里的所有注释代码
        """
        content = []
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
                    content.append(line)
        return content

    def parse_module_name(self, content):
        for line in content:
            if line.find('module') != -1:
                module_name = line.split(' ')[1]
                break

        return module_name

    def parse_module_para(self):
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

    def create_interface_file(self):
        """
        在当前文件目录下，生成基于当前文件的 interface 文件
        :return:
        """
        module_name = self.parse_module_name(self.content)
        port = self.paser_port(self.content)
        file_name = module_name + '_bfm.svh'
        interface_content = 'interface ' + module_name + '_bfm;\n'
        for p in port:
            interface_content += '    '
            interface_content += 'logic '

            if p['width'] != '1':
                interface_content += '[' + p['width'] + ']    ' + p['name'] + ';\n'
            else:
                interface_content += p['name'] + ';\n'
        interface_content += '\nendinterface\n'
        if os.path.exists(file_name) == False:
            f = open(file_name, 'w')
            f.write(interface_content)
            f.close()

    def create_class_file(self):
        """
        在当前文件目录下，生成基于当前文件的 class 文件
        :return:
        """
        module_name = self.parse_module_name(self.content)
        file_name = module_name + '_drive.svh'
        class_content = '`ifndef ' + module_name.upper() + '_SVH\n'
        class_content += '`define ' + module_name.upper() + '_SVH\n\n'
        class_content += 'class ' + module_name + '_drive;\n'
        class_content += '    virtual ' + module_name + '_bfm bfm;\n\n'
        class_content += '    function new(virtual ' + module_name + '_bfm b, string name);\n'
        class_content += '        bfm = b;\n'
        class_content += '    endfunction\n\n'

        class_content += 'extern virtual task execute ();\n\n'
        class_content += 'endclass\n\n'
        class_content += 'task adc_drive::execute ();\n\n'
        class_content += 'endclass\n'

        if os.path.exists(file_name) == False:
            f = open(file_name, 'w')
            f.write(class_content)
            f.close()

    def paste(self):
        txt = self.instance_module()
        vim.command('let @*= "%s"' % txt)
        return txt
EOF

let s:com = "py3"
function! instance#generate()
    " python3 VerilogParse().paste()
    exec s:com 'VerilogParse().paste()'
    echo @*
endfunction

function! instance#interface()
    exec s:com 'VerilogParse().create_interface_file()'
endfunction

function! instance#class()
    exec s:com 'VerilogParse().create_class_file()'
endfunction
