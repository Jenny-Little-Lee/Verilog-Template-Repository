---
name: writing_verilog
description: 以资深FPGA工程师的标准编写整洁、易读且可综合的 Verilog DUT RTL。仅在编写或修改可综合 RTL 时使用本规范；testbench、验证环境、BFM、monitor、scoreboard 和 reference model 不适用本规范，必须使用 SystemVerilog 及其验证语法标准。
---

# Verilog 编写规范

## 适用范围与 testbench 例外

- 本 skill 仅约束可综合的 DUT RTL，不约束 testbench、验证环境、BFM、monitor、scoreboard 或 reference model。
- 只要任务涉及 testbench 或验证环境，即使文件扩展名是 `.v`，也禁止套用本 skill 的 RTL 规则。
- testbench 必须使用 `.sv` 文件，并按 SystemVerilog 语法编写和编译。
- testbench 可以使用 `logic`、`always_ff`、`always_comb`、`interface`、`clocking`、`class`、`queue`、`mailbox`、`assert`、`cover`、`initial`、延时控制、`fork/join`、`task` 和验证用函数等结构。
- 不得强制 testbench 遵循本 skill 的可综合要求、RTL 三段式 FSM、`default_nettype`、RTL 端口/内部信号命名、RTL 代码区段顺序或其他 DUT RTL 规则。
- testbench 应遵循项目已有的 SystemVerilog 验证规范；若项目提供独立的 testbench 标准，应优先读取并执行该标准。

> **重要**：除非另有明确说明，本规范中的所有规则均为强制要求，不得违反。

## 文件级安全规则

- 每个 `.v` 文件必须在文件头之后添加 `` `default_nettype none ``，并在文件末尾恢复 `` `default_nettype wire ``，防止拼写错误产生隐式线网。

## 命名规范

### 大小写

- 所有信号名、变量名和模块名必须使用**小写字母**，其中也包括 `sram`、`dpu`、`cpu`、`fifo` 等缩写。
- 所有常量和参数名必须使用**大写字母**。

```verilog
// 错误示例
module My_Module (
    input Clk,
    input Rst,
    input [width-1:0] DataInput,
    output [width-1:0] RESULt
);

// 正确示例
module my_module (
    input              i_clk,
    input              i_rst,
    input  [WIDTH-1:0] i_data,
    output [WIDTH-1:0] o_result
);
```

> **例外**：原本采用大写命名的宏不得改名，例如 DesignWare/ChipWare 宏、SRAM 宏等。

### 描述性命名

信号、模块、参数和其他设计元素必须使用含义明确的名称。除 `clk`、`rst`、`ack`、`en` 等广泛使用的缩写外，应避免缩写。缩写并不总是清晰，例如 `addr` 既可能表示地址，也可能表示加法器；过度使用缩写会降低代码可读性。

```verilog
// 错误示例
wire din;
wire dout;
wire re;
wire we;
wire raddr;

// 正确示例
wire w_data_in;
wire w_data_out;
wire w_read_en;
wire w_write_en;
wire w_read_address;
```

### 后缀

适用时必须使用下列标准后缀：

| 信号类型                 | 后缀           | 示例                      |
|--------------------------|----------------|---------------------------|
| 时钟信号                 | `_clk`         | `i_sys_clk`               |
| 复位信号                 | `_rst`         | `i_sys_rst`               |
| 使能信号                 | `_en`          | `i_write_en`              |
| 低电平有效信号           | `_n`           | `i_cs_n`, `w_write_n`     |
| 结构体信号               | `_st`          | `r_packet_st`             |
| 流水级信号               | `_d1`, `_d2`   | `i_data_d1`, `i_data_d2`  |
| 有效信号                 | `_valid`       | `w_data_valid`            |
| 就绪信号                 | `_ready`       | `w_data_ready`            |
| 下一周期信号             | `_next`        | `r_state_next`            |

### 前缀

端口优先使用接口前缀；仅内部信号根据声明类型使用 `r_` 或 `w_`。适用时必须使用下列标准前缀：

| 对象类型                | 前缀或格式       | 示例                              |
|-------------------------|------------------|-----------------------------------|
| 普通输入端口            | `i_`             | `i_clk`, `i_data`                 |
| 普通输出端口            | `o_`             | `o_data`, `o_valid`               |
| AXI 从端接口            | `s_`             | `s_axis_tvalid`                   |
| AXI 主端接口            | `m_`             | `m_axis_tvalid`                   |
| 内部 `reg` 信号         | `r_`             | `r_counter`, `r_state`            |
| 内部 `wire` 信号        | `w_`             | `w_data`, `w_data_valid`          |
| 模块实例                | `u_` + 大写名称  | `u_FIFO_CTRL`                     |
| `generate` 块           | `gen_` + 小写名称| `gen_channel`                     |
| `always` 组合逻辑块     | `comb_`          | `always @(*) begin : comb_fsm`    |
| `always` 时序逻辑块     | `ff_`            | `always @(posedge i_clk) begin : ff_state` |
| FSM 状态定义            | `ST_`            | `ST_IDLE`, `ST_BUSY`              |

- 模块类型名保持小写；模块实例标签必须使用 `u_` 前缀，实例名必须全部大写。
- 数字后缀必须通过下划线分隔，例如 `i_data_0`，禁止用 `flag0`、`flag1` 代替 `flag[0]`、`flag[1]`。
- 同类信号较多时优先使用打包总线；仅在语言和工具支持时使用数组，并通过具名 `generate for` 块处理。

## 编码风格

### 缩进

- 每一级缩进必须使用 **4 个空格**。
- **禁止**使用制表符。

### 行长度

- 每行不得超过 **120 个字符**。
- 长行必须在逻辑合理的位置换行，例如逗号或运算符之后；续行应缩进并与起始表达式对齐。

```verilog
// 错误示例
assign result = (a + b) * (c + d) * (e + f) * (g + h) * (i + j) * (k + l) * (m + n) * (o + p) * (q + r) * (s + t);

// 正确示例
assign result = (a + b) * (c + d) * (e + f) * (g + h) * (i + j) * (k + l) *
                (m + n) * (o + p) * (q + r) * (s + t);
```

> **例外**：无法合理拆分的长字符串、文件路径或宏名可以超过 120 个字符。

### 空格

为提高可读性，运算符两侧、逗号之后和分号之后必须使用空格。

- `if`、`else if`、`case` 等关键字后必须保留一个空格再接括号。
- 普通注释的 `//` 后必须保留一个空格。

```verilog
// 错误示例
assign result=(a+b)*(c+d);

// 正确示例
assign result = (a + b) * (c + d);
```

### 对齐

相关声明和赋值必须对齐，以提高可读性。

```verilog
// 错误示例
assign result = (a + b) * (c + d);
assign result2 = (a + b) * (c + d);
assign result10 = (a + b) * (c + d);

// 正确示例
assign result   = (a + b) * (c + d);
assign result2  = (a + b) * (c + d);
assign result10 = (a + b) * (c + d);
```

声明模块时，每个端口和参数必须单独占一行并保持对齐：

- 逻辑相关的端口使用空行和说明注释分组。

```verilog
// 错误示例
module my_module #(parameter WIDTH = 4, parameter DEPTH = 5) (
    input i_clk, input i_rst, input [3:0] i_data, output [3:0] o_result );

// 正确示例
module my_module #(
    parameter WIDTH = 4,
    parameter DEPTH = 5
) (
    //! 时钟输入
    input              i_clk,
    //! 高电平有效同步复位
    input              i_rst,
    //! 数据输入总线
    input  [WIDTH-1:0] i_data,
    //! 结果输出总线
    output [WIDTH-1:0] o_result
);
```

例化模块时，每个端口和参数连接必须单独占一行并保持对齐，并且必须使用名称映射，禁止位置映射：

```verilog
// 错误示例
my_module #(.WIDTH(4), .DEPTH(5)) u_MY_MODULE (.i_clk(i_clk), .i_rst(i_rst), .i_data(i_data), .o_result(o_result));

// 正确示例
my_module #(
    .WIDTH (4),
    .DEPTH (5)
) u_MY_MODULE (
    .i_clk    (i_clk),
    .i_rst    (i_rst),
    .i_data   (i_data),
    .o_result (o_result)
);
```

### 数值字面量

- 数值字面量必须显式指定位宽和进制。
- RTL 赋值中禁止使用未指定位宽的字面量，例如 `4`、`'hFF`。

```verilog
// 错误示例
assign count = 0;
assign mask  = 'hFF;

// 正确示例
assign count = 8'd0;
assign mask  = 8'hFF;
```

---

## 代码结构顺序

模块内部的各代码区域必须按以下顺序排列：

1. `localparam` 声明；对外可配置项使用 `parameter`，仅模块内部使用的常量使用 `localparam`
2. 内部信号声明（`wire`、`reg`）
3. 子模块实例
4. 组合逻辑（`always @(*)` 或 `assign`）
5. 时序逻辑（使用 `always @(posedge i_clk)`，并在逻辑块内部处理同步复位）
6. 形式验证断言（如适用）

---

## 信号声明

- 每个信号必须**单独占一行**进行声明，**禁止**在同一行声明多个信号。
- 使用 `reg` 声明由 `always` 块驱动的寄存器信号。
- 使用 `wire` 声明由 `assign` 或模块输出驱动的组合网络信号。

```verilog
// 错误示例
reg [7:0] r_count, r_data, r_state;

// 正确示例
reg [7:0] r_count;
reg [7:0] r_data;
reg [1:0] r_state;
```

---

## 赋值

### 通用规则

- **禁止**在声明 `reg` 信号时直接初始化。
- 可综合 RTL 中**禁止**使用 `initial` 块。
- 每行只能包含**一条赋值语句**。
- 时序逻辑使用 `always @(posedge i_clk)` 和**非阻塞赋值**（`<=`）。
- **简单**组合逻辑优先使用 `assign`，不要使用 `always @(*)`。
- 包含条件或 `case` 的**复杂**组合逻辑使用 `always @(*)` 和**阻塞赋值**（`=`）。
- **简单**条件逻辑优先使用三目运算符，不要使用 `if/else`。
- 包含多分支或嵌套的**复杂**条件逻辑优先使用 `if/else`，不要使用三目运算符。
- 组合逻辑必须在所有路径上完整赋值：`if/else` 分支必须完整，`case` 必须包含 `default`，禁止推断锁存器。
- 多行三目 `assign` 的条件、真值和假值必须对齐。
- `always` 块之间必须空一行；使用 `end else begin` 同行格式；`begin` 和 `end` 必须与所属语句保持一致缩进。

---

## 复位模式

### 强制采用高电平有效同步复位

- 所有模块统一使用高电平有效同步复位，输入复位端口命名为 `i_rst` 或 `i_<domain>_rst`，不得使用 `rst_n`。
- 带复位的时序逻辑必须使用 `always @(posedge i_clk)`；敏感列表中禁止加入任何复位信号边沿。
- 复位分支必须是 `always` 块最外层的第一个分支。
- 复位条件只能判断复位信号，例如 `if (i_rst)`；禁止将复位信号与其他控制信号组合判断。
- `soft_reset`、`clear`、`flush`、`load_en`、`count_en` 等其他控制必须放在复位分支之后的 `else` 或 `else if` 分支中处理。

```verilog
// 错误示例：使用复位却将复位与 clear 混合判断。
always @(posedge i_clk) begin : ff_counter
    if (i_rst || i_clear) begin
        r_counter <= {WIDTH{1'b0}};
        r_state   <= ST_IDLE;
    end else begin
        r_counter <= r_counter_next;
        r_state   <= r_state_next;
    end
end

// 正确示例：复位采用同步方式，并与其他控制信号分开处理。
always @(posedge i_clk) begin : ff_counter
    if (i_rst) begin
        r_counter <= {WIDTH{1'b0}};
        r_state   <= ST_IDLE;
    end else if (i_clear) begin
        r_counter <= {WIDTH{1'b0}};
        r_state   <= ST_IDLE;
    end else begin
        r_counter <= r_counter_next;
        r_state   <= r_state_next;
    end
end
```

---

## 状态机

### 状态编码

- 状态名必须以 `ST_` 为前缀。模块包含多个 FSM 时，使用 `READ_ST_`、`WRITE_ST_` 等子前缀。
- 状态必须声明为 `localparam`，并**显式指定位宽**。

```verilog
localparam ST_IDLE = 2'd0;
localparam ST_BUSY = 2'd1;
localparam ST_DONE = 2'd2;
```

### 三段式 FSM 编码风格（强制）

需要 FSM 时，必须使用以下**三段式**结构，禁止采用其他 FSM 结构。

#### 第一段：状态寄存器（时序逻辑）

- 使用复位时，必须采用 `always @(posedge i_clk)` 块，并在时钟沿内优先判断高电平有效同步复位 `i_rst`。
- 该逻辑块只能在时钟沿使用 `r_state_next` 更新 `r_state`，或者执行复位。
- 该逻辑块中**禁止**包含状态转移判断和输出逻辑。

```verilog
always @(posedge i_clk) begin : ff_state
    if (i_rst)
        r_state <= ST_IDLE;
    else
        r_state <= r_state_next;
end
```

#### 第二段：下一状态逻辑（组合逻辑）

- 必须使用 `always @(*)` 块。
- 只能根据 `r_state` 和输入确定 `r_state_next`。
- 必须对 `r_state` 使用 `case` 语句。
- 必须包含 `default` 分支，通常赋值为 `ST_IDLE`，以防止推断出锁存器。

```verilog
always @(*) begin : comb_state
    r_state_next = r_state; // 默认保持当前状态
    case (r_state)
        ST_IDLE: begin
            if (i_start)
                r_state_next = ST_BUSY;
        end
        ST_BUSY: begin
            if (i_done)
                r_state_next = ST_DONE;
        end
        ST_DONE: begin
            r_state_next = ST_IDLE;
        end
        default: begin
            r_state_next = ST_IDLE;
        end
    endcase
end
```

#### 第三段：输出逻辑（连续赋值）

- FSM 输出必须在 `always` 块之外使用**连续 `assign` 语句**赋值。
- 输出必须由 `r_state` 产生（Moore 输出），或者由 `r_state` 和输入共同产生（Mealy 输出）。
- **禁止**在过程赋值块（`always` 块）中生成 FSM 输出。

```verilog
assign o_busy  = (r_state == ST_BUSY);
assign o_valid = (r_state == ST_DONE);
```

---

## 内联文档

所有模块都必须使用 `//!` 注释编写内联文档。文档生成器会解析 `//!` 注释；局部说明或行内解释只能使用 `//`。

### 规则

- 所有 `//!` 文档注释和 `//` 普通注释必须使用中文；Verilog 标识符、宏名、协议名和无法准确翻译的技术术语可以保留原文。
- 所有端口和参数都必须使用 `//!` 注释，并将注释放在对应端口或参数声明的紧前一行。
- 含义明确的内部信号无需额外编写文档。

### 模块文档示例

```verilog
//! 实现寄存器堆的存储部分。
//!
//! 按照 <register_page.REGISTER_FILE_DEPTH> 参数例化多个
//! `register_row`。
//!
module my_module #(
    //! 数据总线位宽
    parameter WIDTH = 4,
    //! 存储深度
    parameter DEPTH = 5
) (
    //! 时钟输入
    input              i_clk,
    //! 高电平有效同步复位
    input              i_rst,
    //! 数据输入总线
    input  [WIDTH-1:0] i_data,
    //! 结果输出总线
    output [WIDTH-1:0] o_result
);
```

---

## 完整示例

下面给出一个遵循上述全部规则的可综合 RTL 模块完整示例：

```verilog
`default_nettype none

//! 带同步加载和高电平有效同步复位的简单递增计数器。
//!
module up_counter #(
    //! 计数器位宽
    parameter WIDTH = 8
) (
    //! 时钟输入
    input                  i_clk,
    //! 高电平有效同步复位
    input                  i_rst,
    //! 计数使能
    input                  i_count_en,
    //! 同步加载使能
    input                  i_load_en,
    //! 加载数据
    input      [WIDTH-1:0] i_load_data,
    //! 计数器输出
    output reg [WIDTH-1:0] o_count,
    //! 溢出标志：计数器从最大值回绕到零时拉高
    output                 o_overflow
);

    // -------------------------------------------------------------------------
    // 局部参数
    // -------------------------------------------------------------------------
    localparam MAX_COUNT = {WIDTH{1'b1}};

    // -------------------------------------------------------------------------
    // 内部信号
    // -------------------------------------------------------------------------
    reg [WIDTH-1:0] r_count_next;

    // -------------------------------------------------------------------------
    // 组合逻辑
    // -------------------------------------------------------------------------

    // 下一计数值逻辑
    always @(*) begin : comb_count
        if (i_load_en)
            r_count_next = i_load_data;
        else if (i_count_en)
            r_count_next = o_count + {{(WIDTH-1){1'b0}}, 1'b1};
        else
            r_count_next = o_count;
    end

    assign o_overflow = i_count_en & (o_count == MAX_COUNT);

    // -------------------------------------------------------------------------
    // 时序逻辑
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin : ff_count
        if (i_rst)
            o_count <= {WIDTH{1'b0}};
        else
            o_count <= r_count_next;
    end

endmodule

`default_nettype wire
```
