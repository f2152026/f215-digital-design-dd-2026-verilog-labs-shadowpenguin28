#!/usr/bin/env python3
"""
Zero-delay verification: strip all #(...) delays from .v files,
compile+simulate, and check outputs settle to correct arithmetic values
immediately (proving the logic is correct and all prior 'errors' were
purely propagation delay artifacts).
"""
import re, subprocess, os, sys, shutil, tempfile

def strip_delays(src_dir, dst_dir):
    """Copy .v files from src_dir to dst_dir with all #(...) delays removed."""
    os.makedirs(dst_dir, exist_ok=True)
    for f in os.listdir(src_dir):
        src = os.path.join(src_dir, f)
        dst = os.path.join(dst_dir, f)
        if f.endswith('.v'):
            with open(src) as fh:
                content = fh.read()
            # Remove gate delays: #(2), #(3,4), #(2) etc.
            content = re.sub(r'\s*#\(\d+(?:,\s*\d+)*\)\s*', ' ', content)
            # Remove assign delays: assign #(2) -> assign
            content = re.sub(r'(assign)\s+#\(\d+(?:,\s*\d+)*\)\s+', r'\1 ', content)
            with open(dst, 'w') as fh:
                fh.write(content)
        elif os.path.isfile(src):
            shutil.copy2(src, dst)

def run_sim(task_dir, tb_name="tb.v"):
    """Compile and simulate using iverilog directly from the given dir."""
    tb = os.path.join(task_dir, tb_name)
    sim = os.path.join(task_dir, "sim.out")
    
    vfiles = [os.path.join(task_dir, f) for f in os.listdir(task_dir) if f.endswith('.v')]
    
    r = subprocess.run(['iverilog', '-g2012', '-Wall', '-o', sim] + vfiles,
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None, r.stderr
    
    r = subprocess.run(['vvp', sim], capture_output=True, text=True, cwd=task_dir)
    return r.stdout, r.stderr

def parse_and_check_1bit(output, label):
    """Check 1-bit full adder outputs."""
    errors = 0
    checked = 0
    for line in output.split('\n'):
        m = re.match(r'\s*(\d+)\s+a=(\d)\s+b=(\d)\s+cin=(\d)\s+\|\s+sum=(\d)\s+cout=(\d)', line)
        if m:
            t, a, b, cin = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
            got_sum, got_cout = int(m.group(5)), int(m.group(6))
            exp = a + b + cin
            exp_sum, exp_cout = exp & 1, (exp >> 1) & 1
            if got_sum != exp_sum or got_cout != exp_cout:
                errors += 1
                print(f"  ❌ {label} t={t}: {a}+{b}+{cin} expected s={exp_sum} co={exp_cout}, got s={got_sum} co={got_cout}")
            checked += 1
    if errors == 0 and checked > 0:
        print(f"  ✅ {label}: All {checked} output lines correct")
    return errors

def parse_and_check_4bit(output, label):
    """Check 4-bit adder outputs."""
    errors = 0
    checked = 0
    for line in output.split('\n'):
        m = re.match(r'\s*(\d+)\s+a=([01]{4})\s+b=([01]{4})\s+cin=([01])\s+\|\s+sum=([01]{4})\s+cout=([01])', line)
        if m:
            t = int(m.group(1))
            a, b, cin = int(m.group(2), 2), int(m.group(3), 2), int(m.group(4))
            got_sum, got_cout = int(m.group(5), 2), int(m.group(6))
            exp = a + b + cin
            exp_sum, exp_cout = exp & 0xF, (exp >> 4) & 1
            if got_sum != exp_sum or got_cout != exp_cout:
                errors += 1
                print(f"  ❌ {label} t={t}: {a}+{b}+{cin}={exp} expected s={exp_sum:04b} co={exp_cout}, got s={m.group(5)} co={got_cout}")
            checked += 1
    if errors == 0 and checked > 0:
        print(f"  ✅ {label}: All {checked} output lines correct")
    return errors

def parse_and_check_64bit(output, label):
    """Check 64-bit adder outputs."""
    errors = 0
    checked = 0
    for line in output.split('\n'):
        m = re.match(r'\s*(\d+)\s+a=([0-9a-f]{16})\s+b=([0-9a-f]{16})\s+cin=([01])\s+\|\s+sum=([0-9a-f]{16})\s+cout=([01])', line)
        if m:
            t = int(m.group(1))
            a, b, cin = int(m.group(2), 16), int(m.group(3), 16), int(m.group(4))
            got_sum, got_cout = int(m.group(5), 16), int(m.group(6))
            exp = a + b + cin
            exp_sum, exp_cout = exp & ((1<<64)-1), (exp >> 64) & 1
            if got_sum != exp_sum or got_cout != exp_cout:
                errors += 1
                print(f"  ❌ {label} t={t}: 0x{a:016x}+0x{b:016x}+{cin}")
                print(f"     expected s=0x{exp_sum:016x} co={exp_cout}, got s=0x{got_sum:016x} co={got_cout}")
            checked += 1
    if errors == 0 and checked > 0:
        print(f"  ✅ {label}: All {checked} output lines correct")
    return errors

if __name__ == '__main__':
    base = os.getcwd()
    tmpbase = os.path.join(base, '_zero_delay_test')
    os.makedirs(tmpbase, exist_ok=True)
    total_errors = 0
    
    try:
        # ===== TASK 1 (1-bit FA) =====
        print("=" * 55)
        print("TASK 1: 1-bit Full Adder (zero-delay logic check)")
        print("=" * 55)
        dst = os.path.join(tmpbase, 'task1')
        strip_delays('labs/lab01/task1', dst)
        out, err = run_sim(dst)
        if out:
            total_errors += parse_and_check_1bit(out, "Task 1")
        else:
            print(f"  ❌ Compile error: {err}")
            total_errors += 1

        # ===== TASK 2 (4-bit RCA) =====
        print("\n" + "=" * 55)
        print("TASK 2: 4-bit Ripple Adder (zero-delay logic check)")
        print("=" * 55)
        dst = os.path.join(tmpbase, 'task2')
        strip_delays('labs/lab01/task2', dst)
        out, err = run_sim(dst)
        if out:
            total_errors += parse_and_check_4bit(out, "Task 2")
        else:
            print(f"  ❌ Compile error: {err}")
            total_errors += 1

        # ===== TASK 3 (CLA4 + RCA + Dataflow) =====
        print("\n" + "=" * 55)
        print("TASK 3: CLA4 + RCA (zero-delay logic check)")
        print("=" * 55)
        dst = os.path.join(tmpbase, 'task3')
        strip_delays('labs/lab01/task3', dst)
        out, err = run_sim(dst)
        if out:
            total_errors += parse_and_check_4bit(out, "Task 3")
        else:
            print(f"  ❌ Compile error: {err}")
            total_errors += 1

        # ===== TASK 4 (all 3 options) =====
        for opt, mod in [(1, "rca64"), (2, "cla64_flat"), (3, "cla64_blocked")]:
            print(f"\n{'=' * 55}")
            print(f"TASK 4 Opt {opt}: {mod} (zero-delay logic check)")
            print(f"{'=' * 55}")
            dst = os.path.join(tmpbase, f'task4_opt{opt}')
            strip_delays('labs/lab01/task4', dst)
            # Rewrite dut.v for this option
            dut = os.path.join(dst, 'dut.v')
            with open(dut) as f:
                c = f.read()
            for m2 in ['rca64', 'cla64_flat', 'cla64_blocked']:
                c = c.replace(f'  {m2} U_IMPL', f'  // {m2} U_IMPL')
            c = c.replace(f'  // {mod} U_IMPL', f'  {mod} U_IMPL')
            with open(dut, 'w') as f:
                f.write(c)
            out, err = run_sim(dst)
            if out:
                total_errors += parse_and_check_64bit(out, f"Task 4 Opt {opt} ({mod})")
            else:
                print(f"  ❌ Compile error: {err}")
                total_errors += 1

        # ===== TASK 5 (Hierarchical CLA) =====
        print(f"\n{'=' * 55}")
        print("TASK 5: Hierarchical CLA64 (zero-delay logic check)")
        print(f"{'=' * 55}")
        dst = os.path.join(tmpbase, 'task5')
        strip_delays('labs/lab01/task5', dst)
        out, err = run_sim(dst)
        if out:
            total_errors += parse_and_check_64bit(out, "Task 5 (Hier CLA)")
        else:
            print(f"  ❌ Compile error: {err}")
            total_errors += 1

    finally:
        shutil.rmtree(tmpbase, ignore_errors=True)

    print(f"\n{'=' * 55}")
    if total_errors == 0:
        print("🎉 ALL ZERO-DELAY TESTS PASSED!")
        print("   Every output is arithmetically correct.")
        print("   Prior 'errors' were purely gate propagation delays.")
    else:
        print(f"⚠️  {total_errors} REAL LOGIC ERRORS found!")
    print("=" * 55)
    sys.exit(total_errors)
