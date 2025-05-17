


%option noyywrap
%{
    /*
        这部分会被原样拷贝到生成的cpp文件的开头
    */
#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstring>
#include <vector>
#include <tuple>

// 定义token类型
#define INT 258
#define VOID 259
#define IF 260
#define ELSE 261
#define RETURN 262
#define IDENT 263
#define ADD 264
#define SUB 265
#define MUL 266
#define DIV 267
#define MOD 268
#define LPAREN 269
#define RPAREN 270
#define LBRACKET 271
#define RBRACKET 272
#define LBRACE 273
#define RBRACE 274
#define INTCONST 275
#define LESS 276
#define GREATER 277
#define EQUAL 278
#define NOT 279
#define LESS_EQUAL 280
#define GREATER_EQUAL 281
#define NOT_EQUAL 282
#define AND 283
#define OR 284
#define ASSIGN 285
#define COMMA 286
#define SEMICOLON 287
#define ERROR 288

// 全局变量
int line_number = 0;
int column_start_number = 0;
int column_end_number = 0;
int current_token;
bool is_head_print = false;
std::ofstream out_file("lexer_output.txt");

// 存储所有token信息的向量
std::vector<std::tuple<int, std::string, int, int, int>> tokens;

// 打印信息函数
void print_msg(std::ostream &out) {
    if(!is_head_print){
        out << std::setw(10) << "Token"
            << std::setw(10) << "Text"
            << std::setw(10) << "line"
            << std::setw(10) << "(s,e)"
            << std::endl;
        out_file << std::setw(10) << "Token"
                 << std::setw(10) << "Text"
                 << std::setw(10) << "line"
                 << std::setw(10) << "(s,e)"
                 << std::endl;
        is_head_print = true;
    }
    
    out << std::setw(10) << current_token  
        << std::setw(10) << yytext  
        << std::setw(10) << line_number
        << std::setw(10) << column_start_number << "," << column_end_number
        << std::endl;
    out_file << std::setw(10) << current_token  
             << std::setw(10) << yytext  
             << std::setw(10) << line_number
             << std::setw(10) << column_start_number << "," << column_end_number
             << std::endl;
}

// 错误处理函数
void errorprinter(const char *msg) {
    std::cerr << "Error at line " << line_number 
              << ", column " << column_start_number 
              << ": " << msg << " '" << yytext << "'" 
              << std::endl;
    out_file << "Error at line " << line_number 
             << ", column " << column_start_number 
             << ": " << msg << " '" << yytext << "'" 
             << std::endl;
}

// 处理token的核心函数
int handle_token(int token) {
    if (token == ERROR) {
        errorprinter("Invalid token");
        return token;
    }

    current_token = token;
    column_start_number = column_end_number;
    column_end_number += strlen(yytext);
    
    // 只记录有意义的token
    if (token != ' ' && token != '\t' && token != '\n' && token != '\r' &&
        strcmp(yytext, "//") != 0 && strncmp(yytext, "/*", 2) != 0) {
        // 保存 token 信息
        tokens.emplace_back(current_token, yytext, line_number, column_start_number, column_end_number);
    }
    return token;
}
%}

%%


"/*"([^*]|\*+[^*/])*\*+"/"  {
    column_start_number = column_end_number;
    for (unsigned i = 0; i < strlen(yytext); i++) {
        if (yytext[i] == '\n') {
            line_number++;
            column_end_number = 0;
        } else {
            column_end_number++;
        }
    }
}

"//".*  { column_start_number = column_end_number; column_end_number += strlen(yytext); }

"int"       { return handle_token(INT); }
"void"      { return handle_token(VOID); }
"if"        { return handle_token(IF); }
"else"      { return handle_token(ELSE); }
"return"    { return handle_token(RETURN); }
[a-zA-Z_][a-zA-Z0-9_]*  { return handle_token(IDENT); }
[0-9]+      { return handle_token(INTCONST); }

"+"     { return handle_token(ADD); }
"-"     { return handle_token(SUB); }
"*"     { return handle_token(MUL); }
"/"     { return handle_token(DIV); }
"%"     { return handle_token(MOD); }
"("     { return handle_token(LPAREN); }
")"     { return handle_token(RPAREN); }
"["     { return handle_token(LBRACKET); }
"]"     { return handle_token(RBRACKET); }
"{"     { return handle_token(LBRACE); }
"}"     { return handle_token(RBRACE); }
"<"     { return handle_token(LESS); }
"<="    { return handle_token(LESS_EQUAL); }
">"     { return handle_token(GREATER); }
">="    { return handle_token(GREATER_EQUAL); }
"=="    { return handle_token(EQUAL); }
"!="    { return handle_token(NOT_EQUAL); }
"&&"    { return handle_token(AND); }
"||"    { return handle_token(OR); }
"!"     { return handle_token(NOT); }
"="     { return handle_token(ASSIGN); }
","     { return handle_token(COMMA); }
";"     { return handle_token(SEMICOLON); }

\n      { line_number++; column_start_number = 0; column_end_number = 0; }
[ \r]   { column_start_number = column_end_number; column_end_number += strlen(yytext); }
\t      { column_start_number = column_end_number; column_end_number += 4; }

.       { return handle_token(ERROR); }

%%

// 修改后的main函数
int main(int argc, char *argv[]) {
    if (argc == 2) {
        // 如果指定了文件，尝试打开文件
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            std::cerr << "Error: Unable to open file " << argv[1] << std::endl;
            return EXIT_FAILURE;
        }
        std::cout << "Analyzing code from " << argv[1] << ":" << std::endl;
    } else {
        // 如果没有指定文件，使用标准输入
        std::cout << "Enter your code (end with Ctrl+D):" << std::endl;
        yyin = stdin;
        // 禁用缓冲，确保即时处理输入
        setvbuf(stdin, NULL, _IONBF, 0);
    }

    // 循环处理输入直到EOF
    while (yylex() != 0) {
        // 处理直到输入结束
    }

    // 在输入结束后输出所有结果
    if (!tokens.empty()) {
        std::cout << std::setw(10) << "Token"
                  << std::setw(10) << "Text"
                  << std::setw(10) << "line"
                  << std::setw(10) << "(s,e)"
                  << std::endl;
        
        for (const auto& token_info : tokens) {
            std::cout << std::setw(10) << std::get<0>(token_info)
                      << std::setw(10) << std::get<1>(token_info)
                      << std::setw(10) << std::get<2>(token_info)
                      << std::setw(10) << std::get<3>(token_info) << "," << std::get<4>(token_info)
                      << std::endl;
        }
    }

    out_file.close();
    return 0;
}