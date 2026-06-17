// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SafeDepositBox{

    struct Student{
        string  name;
        uint8   grade;
        uint8  age;
        uint8  gender;   // 1 -female , 2-male
    }
    struct Courses{
        string  name;
        uint8 courseCode;
        uint8  grade;
        
       
    }
    mapping(address =>  Courses[]) public records;
    mapping(address => Student) public students;

    function addRecord(string calldata _name , uint8 _grade ,uint8 _age , bool _female ) public {
        uint8 sex;
        if(_female){
            sex = 1;
        }else{
            sex = 2;
        }
        Student memory stu1 = Student(_name , _grade , _age, sex);
        students[msg.sender] = stu1;
    }
    function addMarks(string calldata _name ,uint8 _code, uint8 _mark)public {
    Courses memory course1 = Courses(_name , _code ,_mark);
    records[msg.sender].push(course1);


}

}