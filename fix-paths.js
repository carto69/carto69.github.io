import { readFileSync, writeFileSync } from 'fs';
import { resolve } from 'path';

const indexPath = resolve('dist/index.html');
let html = readFileSync(indexPath, 'utf-8');

html = html.replace(/href="\/assets\//g, 'href="./assets/');
html = html.replace(/src="\/assets\//g, 'src="./assets/');

writeFileSync(indexPath, html);
console.log('✓ Fixed paths in dist/index.html');
