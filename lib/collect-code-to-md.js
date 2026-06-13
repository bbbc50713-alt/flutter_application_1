const fs = require('fs');
const path = require('path');
const readline = require('readline');

// const ignoreDirs = ['node_modules', 'dist'];
// const codeExtensions = ['.js', '.ts', '.vue', '.json', '.html', '.css', '.scss', '.md'];

// 扩展忽略目录列表
const ignoreDirs = ['node_modules', 'dist', 'build', '.git', '.vscode', '__pycache__', '.idea'];
// 扩展文件类型列表
const codeExtensions = [
  // 编程语言文件
  '.js', '.jsx', '.ts', '.tsx', '.vue', '.py', '.java', '.cpp', '.c', '.h', '.cs', '.php', '.rb', '.go', '.rs','.dart',
  // 配置文件
  '.json', '.yaml', '.yml', '.xml', '.conf', '.config', '.ini', '.toml', '.env',
  // 脚本文件
  '.sh', '.bash', '.zsh', '.ps1', '.bat', '.cmd',
  // 网页相关
  '.html', '.htm', '.css', '.scss', '.sass', '.less',
  // 文档文件
  '.md', '.markdown', '.txt', '.rst',
  // 数据库文件
 '.sqlite', '.sql', 
  // 其他
  '.dockerfile', 'dockerfile', '.gitignore', '.gitattributes'
];

function isDirectory(p) {
  return fs.existsSync(p) && fs.statSync(p).isDirectory();
}

function isCodeFile(filename) {
  return codeExtensions.includes(path.extname(filename));
}

function collectFiles(dir, baseDir, allFiles = []) {
  const entries = fs.readdirSync(dir);
  for (const entry of entries) {
    const fullPath = path.join(dir, entry);
    const relativePath = path.relative(baseDir, fullPath);

    if (fs.statSync(fullPath).isDirectory()) {
      if (!ignoreDirs.includes(entry)) {
        collectFiles(fullPath, baseDir, allFiles);
      }
    } else if (isCodeFile(entry)) {
      allFiles.push({ fullPath, relativePath });
    }
  }
  return allFiles;
}

function appendFilesToMarkdown(files, outputFile) {
  const output = fs.createWriteStream(outputFile, { flags: 'w' });

  for (const { fullPath, relativePath } of files) {
    const content = fs.readFileSync(fullPath, 'utf-8');
    output.write(`文件名: ${relativePath}\n`);
    output.write(`文件内容:\n`);
    output.write(`${content.trim()}\n`);
    output.write(`================\n\n`);
  }

  output.end();
  console.log('✅ 所有代码已写入', outputFile);
}

function askDirectoryInput() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  rl.question('请输入要扫描的项目文件夹路径（如 ./ 或 A:/xxx/project）：', (inputDir) => {
    const resolvedDir = path.resolve(inputDir.trim());
    if (!isDirectory(resolvedDir)) {
      console.error('❌ 输入的路径不是一个有效的目录！');
      rl.close();
      return;
    }

    const outputFile = path.join(resolvedDir, 'all_code.md');
    const allFiles = collectFiles(resolvedDir, resolvedDir);
    appendFilesToMarkdown(allFiles, outputFile);
    rl.close();
  });
}

askDirectoryInput();
