CREATE OR REPLACE FUNCTION SYS.verify_function
  (username       IN varchar2,
   password       IN varchar2,
   old_password   IN varchar2)
RETURN boolean
IS
   n boolean;
   m integer;
   differ integer;
   isdigit boolean    := FALSE;
   ischar  boolean    := FALSE;
   ispunct boolean    := FALSE;
   digitarray varchar2(20);
   punctarray varchar2(25);
   chararray varchar2(52);

BEGIN
   digitarray:= '0123456789';
   chararray:= 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
   punctarray:='!"#$%&()``*+,-/:;<=>?_';

   -- Check if the password is same as the username
   IF SUBSTR(NLS_LOWER(password),1, 5) = SUBSTR(NLS_LOWER(username), 1, 5) THEN
     raise_application_error(-20001, 'Password same as or similar to user');
   END IF;

   -- Check for the minimum length of the password
   IF length(password) < 8 THEN
      raise_application_error(-20002, 'Password length less than 8');
   END IF;

   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF NLS_LOWER(password) IN
        ('welcome', 'database', 'account', 'user', 'password', 'oracle', 'computer')
      OR INSTR(NLS_LOWER(password), 'perseco') > 0
      OR INSTR(NLS_LOWER(password), 'abcd')    > 0
      OR INSTR(NLS_LOWER(password), 'test')    > 0
      OR INSTR(NLS_LOWER(password), '1234')    > 0
   THEN
      raise_application_error(-20003, 'Password too simple. Common substrings detected.');
   END IF;

   -- ensure password does not contain specified characters
   IF (INSTR(password, '@') > 0) THEN
      raise_application_error(-20004, 'Password cannot contain specified character: "@"');
   END IF;

   -- Check if the password contains at least one letter and (one digit or one
   -- punctuation mark).

   -- 1. Check for the digit or punctuation mark
   m := length(password);
   FOR i IN 1..10 LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(digitarray,i,1) THEN
            GOTO findchar;
         END IF;
      END LOOP;
   END LOOP;
   -- 2. Check for the punctuation
   <<findpunct>>
   FOR i IN 1..length(punctarray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(punctarray,i,1) THEN
            GOTO findchar;
         END IF;
      END LOOP;
   END LOOP;

   GOTO validation_error;

   -- 3. Check for the character
   <<findchar>>
   FOR i IN 1..length(chararray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(chararray,i,1) THEN
            GOTO endsearch;
         END IF;
      END LOOP;
   END LOOP;

   <<validation_error>>
   raise_application_error(-20005, 'Password should contain at least ' ||
     'one character and one digit or punctuation mark');

   <<endsearch>>
   -- Check if the password differs from the previous password by at least
   -- 3 letters
   IF old_password IS NOT NULL THEN
     differ := length(old_password) - length(password);

     IF abs(differ) < 3 THEN
       IF length(password) < length(old_password) THEN
         m := length(password);
       ELSE
         m := length(old_password);
       END IF;

       differ := abs(differ);
       FOR i IN 1..m LOOP
         IF substr(password,i,1) != substr(old_password,i,1) THEN
           differ := differ + 1;
         END IF;
       END LOOP;

       IF differ < 3 THEN
         raise_application_error(-20006, 'Password should differ by at least 3 characters');
       END IF;
     END IF;
   END IF;

   -- Everything is fine; return TRUE ;
   RETURN(TRUE);
END verify_function;
/
