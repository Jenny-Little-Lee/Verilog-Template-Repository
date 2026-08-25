# 波形示例

## 保存全部波形数据

在 `*_simulate.do` 中完成设计加载后，先递归记录 testbench 顶层，再执行波形布局脚本和仿真：

```tcl
log -r /tb_name/*
do tb_name_wave.do
run -all
```

`log -r` 决定 WLF 中保存哪些信号。不要用 `add wave -r` 代替它。如果内部信号因优化不可见，检查 `vsim` 是否包含适当的信号访问选项，例如 `-voptargs=+acc`。

## 按模块实例分组

每个实例只加入本层直接信号；DUT 子实例分别建立分组，避免同一信号被递归加入多个组。使用完整实例路径生成组名，避免同名实例冲突。

```tcl
proc add_scope_wave_group {scope} {
    if {[catch {set signals [find signals ${scope}/*]} message]} {
        puts [format {WARNING: cannot enumerate signals in %s: %s} $scope $message]
        return
    }

    if {[llength $signals] == 0} {
        return
    }

    set group_name [string map {/ .} [string trimleft $scope /]]
    if {[catch {eval add wave -group [list $group_name] $signals} message]} {
        puts [format {WARNING: cannot add wave group %s: %s} $group_name $message]
    }
}

# Testbench 顶层和 DUT 顶层。
add_scope_wave_group /tb_name
add_scope_wave_group /tb_name/u_dut

# DUT 的全部子模块实例。
if {![catch {set dut_scopes [find instances -recursive /tb_name/u_dut/*]}]} {
    foreach scope $dut_scopes {
        add_scope_wave_group $scope
    }
}
```

## 单个信号

用户明确要求额外突出某个信号时，可以在分组之后单独添加：

```tcl
add wave /tb_name/u_dut/signal_name
```

生成 WLF 后，至少验证其中存在 testbench 顶层、DUT 顶层以及一个深层 DUT 子实例的信号。
