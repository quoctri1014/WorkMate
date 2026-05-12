import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Replace hardcoded Colors.white with adaptive color
    content = re.sub(r'Colors\.white', r'Theme.of(context).colorScheme.surface', content)
    
    # Replace background
    content = re.sub(r'AppColors\.background', r'Theme.of(context).scaffoldBackgroundColor', content)
    content = re.sub(r'Color\(0xFFF5F7F9\)', r'Theme.of(context).scaffoldBackgroundColor', content)
    content = re.sub(r'Color\(0xFFF0F2F5\)', r'Theme.of(context).colorScheme.surfaceVariant', content)
    
    # Replace text colors
    content = re.sub(r'AppColors\.textPrimary', r'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'Color\(0xFF1a1a1a\)', r'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'Colors\.black87', r'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'Colors\.black', r'Theme.of(context).colorScheme.onSurface', content)
    content = re.sub(r'AppColors\.textSecondary', r'Theme.of(context).colorScheme.onSurfaceVariant', content)

    if content != original_content:
        # Strip `const ` from lines that now contain `Theme.of(context)`
        lines = content.split('\n')
        for i in range(len(lines)):
            if 'Theme.of(context)' in lines[i] and 'const ' in lines[i]:
                lines[i] = lines[i].replace('const ', '')
        content = '\n'.join(lines)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

for root, dirs, files in os.walk('lib/presentation/views'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
