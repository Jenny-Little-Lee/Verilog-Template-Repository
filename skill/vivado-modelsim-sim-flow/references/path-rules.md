# 路径规则

- Vivado 工程打开路径：`<vivado_project_dir>`
- Vivado 行为级仿真目录：`Work_Dir/*.sim/sim_1/behav/modelsim`
- WLF 输出路径示例：`../../../../../testbench/<tb_name>/runs/latest/waves/<tb_name>.wlf`
- ModelSim 的相对路径是相对于当前 ModelSim 运行目录，而不是工程根目录。
- testbench 源码里的 `$dumpfile`、`$fopen`、`$readmemh` 路径，也要按当前 ModelSim 运行目录来判断。
- `launch_simulation` 后 Vivado 可能重写 `compile.bat`、`simulate.bat`、`*_simulate.do`、`*_wave.do`。
- 相对路径有争议时，可临时改成绝对路径验证链路是否通。
- 运行 Vivado batch 时，优先将工作目录设为目标 testbench 的 `runs/<timestamp>/vivado/` 或 `runs/latest/vivado/`，不要默认在工程根目录执行。

## testbench 目录建议

- 每个 testbench 使用独立目录：`testbench/<tb_name>/`
- testbench 源码放：`testbench/<tb_name>/tb_src/`
- testbench 输入数据放：`testbench/<tb_name>/data/`
- 手工维护的 Tcl、波形配置、说明文件放：`testbench/<tb_name>/cfg/`
- 多个 testbench 共享的支持文件放：`testbench/common/`

## 运行产物建议

- 每次 skill 运行的副产物归档到：`testbench/<tb_name>/runs/<timestamp>/`
- 最近一次结果可同步到：`testbench/<tb_name>/runs/latest/`
- 临时生成的 Tcl、`*.do`、`compile.bat`、`simulate.bat` 快照放：`testbench/<tb_name>/runs/<timestamp>/scripts/`
- `vivado.log`、`vivado.jou`、`vivado_*.backup.*`、`xvlog.pb`、`xsim.dir/` 放：`testbench/<tb_name>/runs/<timestamp>/vivado/`
- `compile.log`、`simulate.log`、`transcript` 放：`testbench/<tb_name>/runs/<timestamp>/logs/`
- `*.wlf`、`wlft*`、`*.vcd` 放：`testbench/<tb_name>/runs/<timestamp>/waves/`
- `*.csv` 等导出结果放：`testbench/<tb_name>/runs/<timestamp>/exports/`
- 如果临时 Vivado Tcl 是为了某个具体 testbench 生成的，优先直接写入 `testbench/<tb_name>/runs/<timestamp>/scripts/`，不要先落在工程根目录。
- 如果 Vivado batch 仍在工程根目录产生日志文件，运行结束后应立即移动到 `testbench/<tb_name>/runs/<timestamp>/vivado/`。

## 根目录约束

- 工程根目录和 `testbench/` 根目录尽量不保留零散的运行副产物。
- `tmp_set_*.tcl`、`vivado*.log`、`vivado*.jou`、`xvlog.pb`、`xsim.dir/`、`*.wlf` 等文件应随运行结果一起归档。
