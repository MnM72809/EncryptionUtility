#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <stdbool.h>

char getCharNoEcho();
int getMenuSelection(const char* title, const char** options, int optionCount, bool allowEsc);
char* getString(const char* prompt);
char* processPath(const char* path, bool mustExist, bool isDirectory);
bool fileExists(const char* path);
char* readFileContent(const char* filename, size_t* contentLength);
char* getCurrentWorkingDirectory();
void infoHandler(void);

void testHandler(void);
bool createFile(const char* filename);
bool changeWorkingDirectory(const char* newDir);
void changeDirHandler(void);

#endif // FUNCTIONS_H