# ========================================================================
# 卡尔瓦世界设定 Wiki · 每日更新脚本
# ========================================================================
# 用法：每天完成设定修改后，双击运行此脚本（或右键"用 PowerShell 运行"）
# 它会自动做四件事：
#   1) 把 D:\工作区1\世界设定\ 下的最新 Markdown 和图片复制进网站项目
#   2) 用 MkDocs 重新生成静态网页
#   3) 把网页推送到 GitHub，更新你的线上 Wiki
#   4) 内部协作文件（创作实录、变更日志等）不会被复制到网页
# ========================================================================

# ---------- 路径设置（不要改） ----------
$srcDir   = "D:\工作区1\世界设定"          # 你修改设定的地方
$wikiDir  = "D:\工作区1\carva-wiki"        # 网站项目文件夹
$docsDir  = "$wikiDir\docs"                # 网站的文档源文件夹
$py       = "C:\Users\JM\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
$git      = "C:\Program Files\Git\bin\git.exe"

# 把 Git 加入当前会话的 PATH
$env:PATH += ";C:\Program Files\Git\bin;C:\Program Files\Git\usr\bin"

# 不复制以下内部协作文件（仅用于编辑，不发布到网页）：
$exclude = @(
    "LOG-创作实录.md",
    "CHANGELOG.md",
    "HANDOFF-新会话必读.md",
    "PROGRESS-2026-11-19-断点.md",
    "AUDIT-2026-11-19-法术表审计.md"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  卡尔瓦世界设定 Wiki · 每日更新脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ---------- 步骤 1：复制最新设定文档 ----------
Write-Host "`n[步骤 1] 复制最新的设定文档 ..." -ForegroundColor Yellow
Get-ChildItem -Path $srcDir -Include *.md | Where-Object { $exclude -notcontains $_.Name } | Copy-Item -Destination $docsDir -Force
Copy-Item "$srcDir\*.png" -Destination $docsDir -Force
Write-Host "  已同步所有发布用的 .md 和 .png 文件。" -ForegroundColor Green

# ---------- 步骤 2：重新构建静态网站 ----------
Write-Host "`n[步骤 2] 运行 mkdocs build 重新生成网页 ..." -ForegroundColor Yellow
& $py -m mkdocs build --config-file "$wikiDir\mkdocs.yml" --site-dir "$wikiDir\site"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  错误：mkdocs build 失败，请检查上面的错误信息。" -ForegroundColor Red
    exit 1
}
Write-Host "  网页已生成。" -ForegroundColor Green

# ---------- 步骤 3：把构建结果部署到仓库根目录 ----------
Write-Host "`n[步骤 3] 部署文件到仓库根目录 ..." -ForegroundColor Yellow
# 先清理根目录旧的生成文件（保留 docs/、mkdocs.yml、.nojekyll、隐藏的 .git）
$keep = @("docs", "mkdocs.yml", ".nojekyll")
Get-ChildItem -Path $wikiDir | Where-Object { $keep -notcontains $_.Name -and $_.Name -ne ".git" } | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
}
# 把 site/ 下的所有文件移到根目录
Move-Item "$wikiDir\site\*" -Destination $wikiDir -Force
Remove-Item "$wikiDir\site" -Recurse -Force
# 确保 .nojekyll 存在
New-Item "$wikiDir\.nojekyll" -ItemType File -Force | Out-Null
Write-Host "  部署完成。" -ForegroundColor Green

# ---------- 步骤 4：Git 提交并推送 ----------
Write-Host "`n[步骤 4] 提交并推送到 GitHub ..." -ForegroundColor Yellow
& $git add -A
$today = Get-Date -Format "yyyy-MM-dd HH:mm"
& $git commit -m "Wiki 自动更新：$today"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  提示：没有新内容需要提交。" -ForegroundColor Yellow
} else {
    & $git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  错误：git push 失败，请检查网络或 GitHub 登录状态。" -ForegroundColor Red
        exit 1
    }
    Write-Host "  已推送到 GitHub。" -ForegroundColor Green
}

# ---------- 完成 ----------
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  更新完成！" -ForegroundColor Green
Write-Host "  线上网址：https://yuxiaoyang738-stack.github.io/carva-wiki/" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n按任意键关闭此窗口..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
