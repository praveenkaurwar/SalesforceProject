public class StringArrayTest {
    public static List<String> generateStringArray(Integer numberOfStrings){
        List<String> returnStringList = new List<String>();
        system.debug(numberOfStrings);
        for(integer i; i>numberOfStrings; i++){
             returnStringList.add('Test '+i);
            system.debug('current i--->'+i);
        }
        system.debug(returnStringList);
        return returnStringList;
    }
}