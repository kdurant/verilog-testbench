python3 << EOF
import vim
import os
class VerilogParse:
    def __init__(self):
        self.buffer = vim.current.buffer
        # self.buffer = open('location_module.v', 'r', encoding='utf-8').readlines()
        # self.buffer = open('pos_fifo.v', 'r', encoding='utf-8').readlines()

        self.dict = {}

        self.content = self.delete_all_comment()
        self.port = self.paser_port(self.content)
        self.module_name = self.parse_module_name(self.content)
        self.module_para = self.parse_module_para()

    def parse_module_name(self, content):
        """
        找到文件的模块名称
        :param content:
        :return:
        """
        for line in content:
            if line.find('module') != -1:
                module_name = line.split(' ')[1]
                break

        return module_name

    def parse_module_para(self):
        """
        找到文件的模块参数，存放到列表
        :return:
        """
        module_para = []
        para_dict = {}
        for line in self.content:
            if line.find('input') != -1 or line.find('output') != -1 or line.find('inout') != -1 :
                break
            elif line.find('parameter') == 0:
                line = line.replace('parameter', '').strip()
                para_dict['para_name'] = line[:line.find('=')].strip()
                para_dict['para_value'] = line[line.find('=')+1:].replace(',', '').strip().rstrip()

                dict = para_dict.copy()
                module_para.append(dict)

        return module_para

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

    def paser_port(self, content):
        """
        找到verilog里的所有端口, 存放到列表中
        :param content:
        :return:
        """
        port = []
        for i in content:
            line = i.strip()
            # 去掉 '=' 后面所有字符, eg: output reg cnt = 0,
            if line.find('=') != -1:
                line = line[:line.find('=')]
            # 去掉 ',' 后面所有字符
            if line.find(',') != -1:
                line = line[:line.find(',')]
            # 去掉 ';' 后面所有字符
            if line.find(';') != -1:
                line = line[:line.find(';')]

            if line.find('//') != -1:
                line = line[:line.find('//')]    # 如果是最后一行端口声明，去掉注释
            # print(line)

            # 默认always语句后不会再有端口声明
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
                    port.append(dict)
        return port

    def find_sub_module(self):
        pass

    def creat_instance_snippet(self):
        """
        生成模块的例化代码片段
        :return:
        """
        module_name = self.parse_module_name(self.content)
        port = self.port
        module_para = self.module_para

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
            instance_snippet = module_name + ' #\n(\n'
            for ele in module_para:
                if cnt + 1 == len(module_para):  # 最后一个参数
                    instance_snippet += '    .' + ele['para_name'] + (max_length - len(ele['para_name'])) * ' ' + '(' + '  ' + \
                                 ele['para_value'] + (max_length - len(ele['para_value'])) * ' ' + ')'
                    instance_snippet += '\n)\n' + module_name + 'Ex01\n(\n'
                else:
                    instance_snippet += '    .' + ele['para_name'] + (max_length - len(ele['para_name']))*' ' + '(' + '  ' + ele['para_value'] +  (max_length-len(ele['para_value']))*' ' + '),\n'
                    cnt += 1
        else:
            instance_snippet = module_name + ' ' + module_name + 'Ex01' + '\n(\n'

        cnt = 0

        for ele in port:
            if cnt+1 == len(port):
                instance_snippet += '    .' + ele['name'] + (max_length-len(ele['name']))*' ' + '(' + '  ' + ele['name'] + (max_length-len(ele['name'])+4)*' ' + ')'
                instance_snippet += '\n);'
            else:
                instance_snippet += '    .' + ele['name'] + (max_length-len(ele['name']))*' ' + '(' + '  ' + ele['name'] +  (max_length-len(ele['name'])+4)*' ' + '),\n'
            cnt += 1

        vim.command('let @*= "%s"' % instance_snippet)
        return instance_snippet

    def create_interface_file(self):
        """
        在当前文件目录下，生成基于当前文件的 interface 文件
        :return:
        """
        module_name = self.parse_module_name(self.content)
        port = self.port
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

        vim.command('let @*= "%s"' % interface_content)
        vim.command('echo @*')

        #if os.path.exists(file_name) == False:
        #    f = open(file_name, 'w')
        #    f.write(interface_content)
        #    f.close()

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
        class_content += 'task ' + module_name + '_drive::execute ();\n\n'
        class_content += 'endtask\n\n'
        class_content += 'endclass\n'

        vim.command('let @*= "%s"' % class_content)
        vim.command('echo @*')
        #if os.path.exists(file_name) == False:
        #    f = open(file_name, 'w')
        #    f.write(class_content)
        #    f.close()

    def create_testbench_file(self):
        module_name = self.parse_module_name(self.content)
        port_list = self.port
        file_name = module_name + '_tb.sv'
        tb_content = '`timescale 1ns / 1ps\n\n'
        tb_content += 'module ' + module_name + '_tb();\n\n'
        for line in port_list:
            if line['port_type'] == 'input':
                if  line['width'] == '1':
                    tb_content += 'logic ' + line['name'] + ' = 0;\n'
                else:
                    tb_content += 'logic [' + line['width'] + '] ' + line['name'] + ' = 0;\n'
            else:
                if  line['width'] == '1':
                    tb_content += 'logic ' + line['name'] + ';\n'
                else:
                    tb_content += 'logic [' + line['width'] + '] ' + line['name'] + ';\n'
        tb_content += '\n'
        tb_content += self.creat_instance_snippet();
        tb_content += '\n\nendmodule\n'

        vim.command('let @*= "%s"' % tb_content)
        vim.command('echo @*')

        #if os.path.exists(file_name) == False:
        #    vim.command('let @*= "%s"' % tb_content)
        #    f = open(file_name, 'w')
        #    f.write(tb_content)
        #    f.close()
EOF

let s:com = "py3"
function! instance#generate()
    if &filetype == 'verilog'
        exec s:com 'VerilogParse().creat_instance_snippet()'
        echo @*
    else
        echomsg "Only support verilog file"
    end
endfunction

function! instance#interface()
    if &filetype == 'verilog'
        exec s:com 'VerilogParse().create_interface_file()'
    else
        echomsg "Only support verilog file"
    end
endfunction

function! instance#class()
    if &filetype == 'verilog'
        exec s:com 'VerilogParse().create_class_file()'
    else
        echomsg "Only support verilog file"
    end
endfunction

function! instance#testbench()
    if &filetype == 'verilog'
        exec s:com 'VerilogParse().create_testbench_file()'
    else
        echomsg "Only support verilog file"
    end
endfunction
