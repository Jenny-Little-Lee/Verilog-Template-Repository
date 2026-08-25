---
name: vivado-modelsim-sim-flow
description: 使用 Vivado 第三方 ModelSim/Questa 行为级仿真流程时使用。适用于根据 DUT 规格或 RTL 生成自检 testbench（覆盖正常与异常场景、独立组合逻辑参考模型、scoreboard、monitor 和结构化日志），以及检查仿真入口、重设仿真顶层、串行运行仿真、定位首条真实错误、递归记录 testbench 与全部 DUT 层级信号到 WLF、按模块实例层级分组显示波形和处理 WLF 占用问题的场景。
---

# Vivado ModelSim 仿真流程

## 规则

- 用户要求生成 testbench 时，根据 DUT 接口、协议和功能规格从零生成；未要求生成时，优先复用并完善现有 testbench。
- 生成或重构 testbench 前，必须读取 `references/testbench-standards.md` 并逐项落实覆盖矩阵、独立参考模型、自检、monitor 和日志要求。
- testbench 必须自检，不得只产生激励和波形；所有预期输出都必须来自独立参考模型并由 scoreboard 与 DUT 实际输出比较。
- 日志至少包含 `$time`、模块阶段、`valid`、`ready`、`last`、`user`、`keep`、行号和帧号；接口不存在的字段明确打印 `N/A`，不得静默省略。
- 先验证实际仿真入口，再改波形。
- 如果用户未指定观察对象，默认记录 testbench 顶层以及 DUT 全部子层级信号；只有用户明确要求缩小范围时才裁剪。
- 区分波形数据记录与界面显示：使用 `log -r` 决定 WLF 保存哪些信号，使用 `add wave` 决定 Wave 窗口如何显示；不能只执行 `add wave -r`。
- 按模块实例层级分组显示波形。每个实例只添加本层直接信号，子实例单独建立分组，避免递归添加导致信号重复。
- 分组名使用完整实例路径或可唯一识别的层级名，避免不同层级存在同名实例时发生混淆。
- 如果 DUT 内部信号因优化不可见，检查 `vsim` 是否包含适当的信号访问选项，例如 `-voptargs=+acc`。
- `compile.bat` 和 `simulate.bat` 必须串行执行。
- 不要只看日志里有没有 `Error`，要查看第一条真实错误的详细内容、文件、行号和上下文。
- `*_simulate.do` 应在 `run -all` 前递归记录目标 testbench 层级，不要强制加入退出逻辑。
- 相对路径有争议时，允许临时改成绝对路径验证链路是否通。
- `launch_simulation` 可能会立刻触发一次 compile/simulate，不要假设它只生成脚本。
- 每次重新 `launch_simulation` 后，都重新检查 `compile.bat`、`simulate.bat`、`*_simulate.do` 和 `*_wave.do`，不要假设手工修改还在。
- `testbench/` 根目录尽量只保留 testbench 分类目录和共享目录，不保留零散运行副产物。
- 每个 testbench 使用独立目录：`testbench/<tb_name>/`。
- testbench 稳定文件与运行副产物分开存放：稳定文件放 `tb_src/`、`data/`、`cfg/`；运行副产物放 `runs/`。
- skill 运行产生的 Tcl、Vivado 日志、ModelSim 日志、波形、导出文件，都应尽量归档到 `testbench/<tb_name>/runs/<timestamp>/`。
- 如果需要保留最近一次结果，可同步整理到 `testbench/<tb_name>/runs/latest/`。
- 临时生成的 Vivado batch Tcl 不要默认落在工程根目录，应直接生成到目标 testbench 的 `runs/<timestamp>/scripts/` 或 `runs/latest/scripts/`。
- 如果 Vivado batch 在工程根目录生成了 `vivado.jou`、`vivado.log` 等副产物，运行结束后应及时归档到目标 testbench 的 `runs/<timestamp>/vivado/` 或 `runs/latest/vivado/`。
- 运行 Vivado batch 时，不要默认以工程根目录作为工作目录；优先在目标 testbench 的 `runs/<timestamp>/vivado/` 或 `runs/latest/vivado/` 下执行，减少根目录副产物。
- 如果 `simulate.log` 提示 `WLF file currently in use`，不要先假设是用户手动打开了波形文件；先记录日志中的实际占用进程和实际输出文件名。
- 如果 `simulate.log` 已给出占用进程 `ProcessID`，并且用户同意强制关闭，可直接结束该进程后重跑仿真。
- 如果占用进程无法结束，或 `taskkill` 时进程已退出，但仿真已经成功写入备用波形文件，可将该备用文件整理为一个明确的 `.wlf` 文件名交付给用户，避免遗漏。
- 生成 testbench 先看 `references/testbench-standards.md`；处理路径先看 `references/path-rules.md`；处理报错先看 `references/common-errors.md`；添加波形先看 `references/wave-examples.md`。

## 生成 testbench

仅在用户要求新建或重构 testbench 时执行本节。

1. 读取 DUT RTL、参数、端口、时钟/复位、协议说明和已有验证资料，列出可验证功能、约束、正常行为、异常行为和边界条件。规格含糊且会影响预期结果时，先指出歧义，不要从 DUT 输出反推预期值。
2. 编码前建立覆盖矩阵。每个已识别的正常、异常、边界、复位、背压和时序交互场景都必须映射到具体 testcase、激励方法、预期结果和检查点；未覆盖项必须明确记录原因。
3. 组织 testbench，使时钟/复位、DUT 实例、driver、独立参考模型、期望队列、scoreboard/checker、monitor、超时保护和最终汇总职责清晰分离。
4. 使用独立组合逻辑实现 DUT 的功能变换并产生期望值，优先使用 `always_comb`、`function automatic` 或连续赋值。不得实例化第二份 DUT、复用 DUT 输出、读取 DUT 内部信号或逐行复制 DUT RTL 作为参考模型。
5. 对有状态 DUT，允许在 testbench 中独立维护参考状态，但必须使用组合逻辑根据输入和参考状态计算期望输出及下一参考状态，再只在有效时钟事件更新参考状态。
6. 只在协议定义的有效采样事件比较数据，例如 `valid && ready`。比较数据、`last`、`user`、`keep` 及其他协议字段；使用四态严格比较并在不匹配时输出完整上下文，同时累计错误数。
7. 实现无副作用的详细 monitor，记录复位、case 开始/结束、输入/输出握手、背压开始/结束、参考模型结果、实际结果、比较结果、异常、超时和最终统计。避免 driver 与 monitor 的采样竞争。
8. 所有关键日志使用统一格式，至少打印 `$time`、模块阶段、`valid/ready/last/user/keep`、行号和帧号；多接口时增加接口方向或名称。行号、帧号只在协议规定的握手事件更新，并在日志中记录更新前后一致的语义。
9. 每个 testcase 必须有独立名称、开始/结束标记和 PASS/FAIL 结果。仿真结束时汇总 testcase 数、比较数、通过数、失败数、协议错误数和超时数；任何失败都必须使仿真结果明确失败。
10. 生成后先做静态检查，再按下述仿真流程编译和运行。根据实际日志核对覆盖矩阵，不能仅以编译成功或产生 WLF 作为 testbench 完成标准。

## 仿真流程

1. 检查当前 `compile.bat` / `simulate.bat` 是否指向目标 testbench。
2. 如果已指向当前 testbench，直接继续；如果未指向，再打开 Vivado。
3. 如果目标 testbench 还不在工程里，先加入 `sim_1`。
```tcl
add_files -fileset sim_1 -norecurse <tb_file>
```
4. 在 Vivado Tcl Shell 中重新设置仿真顶层并更新编译顺序。临时 Tcl 文件应提前放到目标 testbench 的 `runs/.../scripts/` 下，Vivado batch 的工作目录优先选在该 testbench 的 `runs/.../vivado/` 下。
```tcl
cd <vivado_project_dir>
open_project <project_name>.xpr
set_property top <tb_top_module_name> [get_filesets sim_1]
set_property top_lib <tb_top_library> [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -install_path <modelsim_install_dir>
```
5. 查找 ModelSim 运行目录：`Work_Dir/*.sim/sim_1/behav/modelsim`。
6. 再次确认 `compile.bat` / `simulate.bat` 已指向当前 testbench；未对上就不要继续改波形。
7. 必要时修改 `*_simulate.do`。在 `launch_simulation` 之后再改，避免被 Vivado 覆盖。保留原 `vsim` 参数和仿真顶层，在 `vsim` 命令中设置 WLF 路径，并在设计加载后、`run -all` 前递归记录整个 testbench 层级。
```tcl
vsim -wlf ../../../../../testbench/<tb_name>/runs/latest/waves/<tb_name>.wlf <保留原有的其他参数和仿真顶层>
log -r /<tb_top>/*
do <tb_name>_wave.do
run -all
```
8. 检查 testbench 源码里的 `$dumpfile`、`$fopen`、`$readmemh` 等路径是否相对于 `modelsim` 运行目录可用。
9. 仅在入口确认无误后修改 `*_wave.do`。按照 `references/wave-examples.md` 枚举 testbench 顶层、DUT 顶层和 DUT 全部子实例，为每个实例建立独立分组并仅加入该实例的直接信号。
10. 先运行 `compile.bat`，等待结束。
11. 详细检查 `compile.log`，定位第一条真实错误，不要只看 `Error loading design` 这类汇总信息。
12. `compile.bat` 成功后，再运行 `simulate.bat`。
13. 详细检查 `simulate.log`，定位第一条真实错误的完整上下文。
14. 验证实际生成的 WLF 至少包含一个 testbench 顶层信号、一个 DUT 顶层信号和一个深层 DUT 子实例信号；缺少内部信号时，先检查 `log -r` 的执行位置和 `vsim` 的信号访问选项。
15. 如果 `simulate.log` 出现 `WLF file currently in use` / `Could not open WLF file`：
    - 先记录日志里的 `ProcessID`。
    - 明确告诉用户本次仿真实际写入的是哪个备用 `WLF` 文件。
    - 如果用户同意强制关闭占用进程，可执行 `taskkill /PID <pid> /F` 后再重跑。
    - 如果占用进程无法结束，或 `taskkill` 时进程已退出，但备用 `WLF` 已生成，可复制或改名为一个明确的 `.wlf` 文件后再交付。
16. 打开本次仿真实际写入的 `WLF` 文件；只有在未切换到备用文件时，才默认打开 `testbench/<tb_name>/runs/latest/waves/<tb_name>.wlf`。
17. 如果本次任务包含整理产物或准备长期维护结构，按下述目录语义归档：
    - `testbench/<tb_name>/tb_src/`：testbench 源码和 testbench 专用辅助模块。
    - `testbench/<tb_name>/data/`：输入数据、初始化文件、参考样本。
    - `testbench/<tb_name>/cfg/`：手工维护的 Tcl、波形配置、说明文件。
    - `testbench/<tb_name>/runs/<timestamp>/scripts/`：本次运行临时生成的 Tcl、`*.do`、`compile.bat`、`simulate.bat` 快照。
    - `testbench/<tb_name>/runs/<timestamp>/vivado/`：`vivado.log`、`vivado.jou`、`vivado_*.backup.*`、`xvlog.pb`、`xsim.dir/` 等 Vivado/XSIM 副产物。
    - `testbench/<tb_name>/runs/<timestamp>/logs/`：`compile.log`、`simulate.log`、`transcript`。
    - `testbench/<tb_name>/runs/<timestamp>/waves/`：`*.wlf`、`wlft*`、`*.vcd`。
    - `testbench/<tb_name>/runs/<timestamp>/exports/`：`*.csv` 等导出结果。
    - 多个 testbench 共享的支持文件放 `testbench/common/`，不要在每个 testbench 目录重复拷贝。

## 说明

- Vivado 生成的 `compile.bat` / `simulate.bat` 可能仍指向旧 testbench；如果不先检查入口，后面的 testbench、波形和日志修改都可能落到错误目标上。
- `vsim` 的相对路径是相对于当前 ModelSim 运行目录，而不是工程根目录。
- `log -r /<tb_top>/*` 负责将 testbench 及其下全部 DUT 层级写入 WLF；`add wave` 只负责 Wave 窗口的显示内容和分组布局。
- 波形分组使用模块实例层级而不是只使用 HDL 模块定义名，因为同一个模块定义可能存在多个实例。
- `WLF file currently in use` 常常是瞬时后台进程或残留仿真进程占用，不等于用户一定手动打开了该文件。
- 如果固定 `WLF` 无法写回，但备用波形文件已经成功生成，优先保证交付一个明确可打开的 `.wlf` 文件，而不是只报告临时文件名。
- `tmp_set_*.tcl`、`vivado*.log`、`vivado*.jou`、`xvlog.pb`、`xsim.dir/`、`*.wlf` 这类运行副产物不应长期散落在工程根目录或 `testbench/` 根目录。
- 如果为了切换仿真顶层临时创建了 `tmp_set_*.tcl`，该文件本身也属于运行副产物，应与本次仿真日志和波形一起归档。
