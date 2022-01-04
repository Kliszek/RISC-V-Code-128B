#include <stdio.h>
#include <stdlib.h>

int main()
{
   FILE* input;
   FILE* output;

   input = fopen("128b_codes.txt", "r");
   output = fopen("code128b.bin","wb");

   if(input == NULL || output == NULL)
   {
      printf("Error!");   
      exit(1);             
   }

  int c;
  while((c=fgetc(input)) != EOF)
  {
    if(c==32)
      c = 0;
    else
      c -= '0';
      
    fwrite( &c ,sizeof(char),  1, output);
    
  }
  
  
   fclose(input);
   fclose(output);

   return 0;
}