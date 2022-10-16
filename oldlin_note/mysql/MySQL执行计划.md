# 实验环境

**MySQL-Windows-8.0.26**

**<font color='red'>注意：使用8以下的版本，操作结果可能大不相同。需要注意，我的上头解释可能是MySQL8.0的版本对编辑器进行了优化，所以在此教</font><font color='red'>程中的一些案例不会出现MySQL5.7版本遇到的慢查询问题。</font>**

 

# 使用的数据表

```mysql
# 先创建一个测试库
# 我创建的是test_db库(utf8,utf8_bin)

#进库创建表

create table subject(
id int(10) auto_increment,
name varchar(20),
teacher_id int(10),
primary key (id),
index idx_teacher_id (teacher_id));//学科表
 
 
create table teacher(
id int(10) auto_increment,
name varchar(20),
teacher_no varchar(20),
primary key (id),
unique index unx_teacher_no (teacher_no(20)));//教师表
 
 
create table student(
id int(10) auto_increment,
name varchar(20),
student_no varchar(20),
primary key (id),
unique index unx_student_no (student_no(20)));//学生表
 
 
create table student_score(
id int(10) auto_increment,
student_id int(10),
subject_id int(10),
score int(10),
primary key (id),
index idx_student_id (student_id),
index idx_subject_id (subject_id));//学生成绩表


# 增加索引
alter table teacher add index idx_name(name(20));//教师表增加名字普通索引


# 插入数据
insert into student(name,student_no) values ('zhangsan','20200001'),('lisi','20200002'),('yan','20200003'),('dede','20200004');
 
insert into teacher(name,teacher_no) values('wangsi','T2010001'),('sunsi','T2010002'),('jiangsi','T2010003'),('zhousi','T2010004');
 
insert into subject(name,teacher_id) values('math',1),('Chinese',2),('English',3),('history',4);
 
insert into student_score(student_id,subject_id,score) values(1,1,90),(1,2,60),(1,3,80),(1,4,100),(2,4,60),(2,3,50),(2,2,80),(2,1,90),(3,1,90),(3,4,100),(4,1,40),(4,2,80),(4,3,80),(4,5,100);



-- 表创建与数据初始化
-- 用户表 tbl_user 和用户登录记录表 tbl_user_login_log

DROP TABLE IF EXISTS tbl_user;
CREATE TABLE tbl_user (
  id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  user_name VARCHAR(50) NOT NULL COMMENT '用户名',
  sex TINYINT(1) NOT NULL COMMENT '性别, 1:男，0:女',
  create_time datetime NOT NULL COMMENT '创建时间',
  update_time datetime NOT NULL COMMENT '更新时间',
    remark VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
  PRIMARY KEY (id)
) COMMENT='用户表';


DROP TABLE IF EXISTS tbl_user_login_log;
CREATE TABLE tbl_user_login_log (
  id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  user_name VARCHAR(50) NOT NULL COMMENT '用户名',
  ip VARCHAR(15) NOT NULL COMMENT '登录IP',
  client TINYINT(1) NOT NULL COMMENT '登录端, 1:android, 2:ios, 3:PC, 4:H5',
  create_time datetime NOT NULL COMMENT '创建时间',
  PRIMARY KEY (id)
) COMMENT='登录日志';


# 插入数据
INSERT INTO tbl_user(user_name,sex,create_time,update_time,remark) VALUES
('何天香',1,NOW(), NOW(),'朗眉星目，一表人材'),
('薛沉香',0,NOW(), NOW(),'天星楼的总楼主薛摇红的女儿，也是天星楼的少总楼主，体态丰盈，乌发飘逸，指若春葱，袖臂如玉，风姿卓然，高贵典雅，人称“天星绝香”的武林第一大美女'),
('慕容兰娟',0,NOW(), NOW(),'武林东南西北四大世家之北世家慕容长明的独生女儿，生得玲珑剔透，粉雕玉琢，脾气却是刚烈无比，又喜着火红，所以人送绰号“火凤凰”，是除天星楼薛沉香之外的武林第二大美女'),
('苌婷',0,NOW(), NOW(),'当今皇上最宠爱的侄女，北王府的郡主，腰肢纤细，遍体罗绮，眉若墨画，唇点樱红；虽无沉香之雅重，兰娟之热烈，却别现出一种空灵'),
('柳含姻',0,NOW(), NOW(),'武林四绝之一的添愁仙子董婉婉的徒弟，体态窈窕，姿容秀丽，真个是秋水为神玉为骨，芙蓉如面柳如腰，眉若墨画，唇若点樱，不弱西子半分，更胜玉环一筹; 摇红楼、听雨轩，琵琶一曲值千金!'),
('李凝雪',0,NOW(), NOW(),'李相国的女儿，神采奕奕，英姿飒爽，爱憎分明'),
('周遗梦',0,NOW(), NOW(),'音神传人，湘妃竹琴的拥有者，云髻高盘，穿了一身黑色蝉翼纱衫，愈觉得冰肌玉骨，粉面樱唇，格外娇艳动人'),
('叶留痕',0,NOW(), NOW(),'圣域圣女，肤白如雪，白衣飘飘，宛如仙女一般，微笑中带着说不出的柔和之美'),
('郭疏影',0,NOW(), NOW(),'扬灰右使的徒弟，秀发细眉，玉肌丰滑，娇润脱俗'),
('钟钧天',0,NOW(), NOW(),'天界，玄天九部 - 钧天部的部主，超凡脱俗，仙气逼人'),
('王雁云',0,NOW(), NOW(),'尘缘山庄二小姐，刁蛮任性'),
('许侍霜',0,NOW(), NOW(),'药王谷谷主女儿，医术高明'),
('冯黯凝',0,NOW(), NOW(),'桃花门门主，娇艳如火，千娇百媚');
INSERT INTO tbl_user_login_log(user_name, ip, client, create_time) VALUES
('薛沉香', '10.53.56.78',2, '2019-10-12 12:23:45'),
('苌婷', '10.53.56.78',2, '2019-10-12 22:23:45'),
('慕容兰娟', '10.53.56.12',1, '2018-08-12 22:23:45'),
('何天香', '10.53.56.12',1, '2019-10-19 10:23:45'),
('柳含姻', '198.11.132.198',2, '2018-05-12 22:23:45'),
('冯黯凝', '198.11.132.198',2, '2018-11-11 22:23:45'),
('周遗梦', '198.11.132.198',2, '2019-06-18 22:23:45'),
('郭疏影', '220.181.38.148',3, '2019-10-21 09:45:56'),
('薛沉香', '220.181.38.148',3, '2019-10-26 22:23:45'),
('苌婷', '104.69.160.60',4, '2019-10-12 10:23:45'),
('王雁云', '104.69.160.61',4, '2019-10-16 20:23:45'),
('李凝雪', '104.69.160.62',4, '2019-10-17 20:23:45'),
('许侍霜', '104.69.160.63',4, '2019-10-18 20:23:45'),
('叶留痕', '104.69.160.64',4, '2019-10-19 20:23:45'),
('王雁云', '104.69.160.65',4, '2019-10-20 20:23:45'),
('叶留痕', '104.69.160.66',4, '2019-10-21 20:23:45');

```



# MySQL性能优化之Explain



## explain的用途

```bash
1. 表的读取顺序如何
2. 数据读取操作有哪些操作类型
3. 哪些索引可以使用
4. 哪些索引被实际使用
5. 表之间是如何引用
6. 每张表有多少行被优化器查询
```



## explain的执行效果

```mysql
mysql> explain select * from subject where id = 1\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: subject
   partitions: NULL
         type: const
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 4
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```



## explain包含的字段

首先需要注意：**MYSQL 5.6.3**<font color='red'>以前</font>只能`EXPLAIN SELECT`; **MYSQL5.6.3**<font color='red'>以后</font>就可以`EXPLAIN SELECT,UPDATE,DELETE`

```bash
1. id //select查询的序列号，包含一组数字，表示查询中执行select子句或操作表的顺序
2. select_type //查询类型
3. table //正在访问哪个表
4. partitions //匹配的分区
5. type //访问的类型
6. possible_keys //显示可能应用在这张表中的索引，一个或多个，但不一定实际使用到
7. key //实际使用到的索引，如果为NULL，则没有使用索引
8. key_len //表示索引中使用的字节数，可通过该列计算查询中使用的索引的长度
9. ref //显示索引的哪一列被使用了，如果可能的话，是一个常数，哪些列或常量被用于查找索引列上的值
10. rows //根据表统计信息及索引选用情况，大致估算出找到所需的记录所需读取的行数
11. filtered //查询的表行占表的百分比
12. Extra //包含不适合在其它列中显示但十分重要的额外信息
```



### id字段

#### 1. id相同

```mysql
# 执行顺序从上至下
# 例子：

explain select subject.* from subject,student_score,teacher where subject.id = student_id and subject.teacher_id = teacher.id;

# 读取顺序：teacher > subject > student_score
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211620697.png)



#### 2. id不同

```mysql
# 如果是子查询，id的序号会递增，id的值越大优先级越高，越先被执行
# 例子：

explain select score.* from student_score as score where subject_id = (select id from subject where teacher_id = (select id from teacher where id = 2));

# 读取顺序：teacher > subject > student_score
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211623314.png)



#### 3. id相同又不同

```mysql
# id如果相同，可以认为是一组，从上往下顺序执行
# 在所有组中，id值越大，优先级越高，越先执行
# 例子：

explain 
select subject.* from subject left join teacher on subject.teacher_id = teacher.id 
union 
select subject.* from subject right join teacher on subject.teacher_id = teacher.id;
 
# 读取顺序：2.teacher > 2.subject > 1.subject > 1.teacher
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211626768.png)



### select_type字段

#### 1. SIMPLE

```mysql
# 简单查询，不包含子查询或Union查询
# 例子：

explain select subject.* from subject,student_score,teacher where subject.id = student_id and subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211628576.png)



#### 2. PRIMARY

```mysql
# 查询中若包含任何复杂的子部分，最外层查询则被标记为主查询
# 例子：

explain select score.* from student_score as score where subject_id = (select id from subject where teacher_id = (select id from teacher where id = 2));
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211630718.png)



#### 3. SUBQUERY

```mysql
# 在select或where中包含子查询
# 包含在select中的子查询(不在from子句中)
# 例子：

explain select score.* from student_score as score where subject_id = (select id from subject where teacher_id = (select id from teacher where id = 2));
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211632663.png)



#### 4. DERIVED

```mysql
# 在FROM列表中包含的子查询被标记为DERIVED（衍生），MySQL会递归执行这些子查询，把结果放在临时表中

# 备注：
# MySQL5.7+ 进行优化了，增加了derived_merge（派生合并），默认开启，可加快查询效率
# MySQL5.7 中对 Derived table 做了一个新特性，该特性允许将符合条件的 Derived table 中的子表与父查询的表合并进行直接JOIN，从而简化了执行计划，同时也提高了执行效率；默认情况下，MySQL5.7 中这个特性是开启的
# 可通过 SET SESSION optimizer_switch='derived_merge=on|off' 来开启或关闭当前 SESSION 的该特性
# 例子：

set session optimizer_switch='derived_merge=off';

explain select * from (select * from student where id = 3) as test;

set session optimizer_switch='derived_merge=on';

# 注意：在做多表查询，或者查询的时候产生新的表的时候会出现这个错误：Every derived table must have its own alias（每一个派生出来的表都必须有一个自己的别名）
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211647040.png)



#### 5. UNION

```mysql
# 若第二个select出现在uion之后，则被标记为UNION(在UNION中的第二个和随后的select)
# 例子：

explain select subject.* from subject left join teacher on subject.teacher_id = teacher.id union select subject.* from subject right join teacher on subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211649322.png)



#### 6. UNION RESULT

```mysql
# 从UNION表获取结果的select
# 例子：

explain select subject.* from subject left join teacher on subject.teacher_id = teacher.id union select subject.* from subject right join teacher on subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211651750.png)



#### 7.DEPENDENT UNION

```mysql
# UNION 操作的第二个或之后的 SELECT，依赖于外部查询的结果集
# 例子:

explain select * from tbl_user_login_log where user_name in (select user_name from tbl_user where id =2 union select user_name from tbl_user where id =3);
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203212046236.png)



#### 8.DEPENDENT SUBQUERY

```mysql
# 子查询中的第一个select查询，依赖于外部查询的结果集
# 例子:

explain select * from tbl_user_login_log where user_name in (select user_name from tbl_user where id =2 union select user_name from tbl_user where id =3);
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203212047502.png)



#### 9.MATERIALIZED

```mysql
# 被物化的子查询，MySQL5.6 引入的一种新的 select_type，主要是优化 FROM 或 IN 子句中的子查询。
# 例子:

explain select * from tbl_user where user_name in (select user_name from tbl_user_login_log);
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203212049297.png)



#### 10.UNCACHEABLE SUBQUERY

```mysql
# 对于外层的主表，子查询不可被缓存，每次都需要计算
# 例子：

explain select * from tbl_user where user_name = (select user_name from tbl_user_login_log where id=@@sql_log_bin);
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203212055749.png)



#### 11.UNCACHEABLE UNION

```mysql
# 类似于 UNCACHEABLE SUBQUERY，只是出现在 UNION 操作中
# 例子:

explain select * from tbl_user where user_name in (select user_name from tbl_user_login_log where id = @@sql_log_bin union all select user_name from tbl_user where id = @@sql_log_bin);
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203212059318.png)



<font color='red'>**SIMPLLE、PRIMARY、SUBQUERY、DERIVED 这 4 个在实际工作中碰到的会比较多，看得懂这 4 个就行了，至于其他的，碰到了再去查资料就好了**</font>



### type字段(必须掌握内容)

```mysql
NULL > system > const > eq_ref > ref > fulltext > ref_or_null > index_merge > unique_subquery > index_subquery > range > index > ALL //最好到最差

# 备注：掌握以下10种常见的即可

NULL > system > const > eq_ref > ref > ref_or_null > index_merge > range > index > ALL
```



#### 1. NULL

```mysql
# MySQL能够在优化阶段分解查询语句，在执行阶段用不着再访问表或索引
# 例子：

explain select min(id) from subject;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211700208.png)



#### 2. system

```mysql
# 表只有一行记录（等于系统表），这是const类型的特列，平时不大会出现，可以忽略
# 例子：

set session optimizer_switch='derived_merge=off';

explain select * from (select * from student where id = 3) as test;

set session optimizer_switch='derived_merge=on';
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211707759.png)



#### 3. const

```mysql
# 表示通过索引一次就找到了，const用于比较primary key或uique索引，因为只匹配一行数据，所以很快，如主键置于where列表中，MySQL就能将该查询转换为一个常量
# 例子：

explain select * from teacher where teacher_no = 'T2010001';
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211709240.png)



#### 4. eq_ref

```mysql
# 唯一性索引扫描，对于每个索引键，表中只有一条记录与之匹配，常见于主键或唯一索引扫描
# 例子：

explain select subject.* from subject left join teacher on subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211710367.png)



#### 5. ref

```mysql
# 非唯一性索引扫描，返回匹配某个单独值的所有行
# 本质上也是一种索引访问，返回所有匹配某个单独值的行
# 然而可能会找到多个符合条件的行，应该属于查找和扫描的混合体
# 例子：

explain select subject.* from subject,student_score,teacher where subject.id = student_id and subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211712619.png)



#### 6. ref_or_null

```mysql
# 类似ref，但是可以搜索值为NULL的行
# 例子：

explain select * from teacher where name = 'wangsi' or name is null;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211713906.png)



#### 7. index_merge

```mysql
# 表示使用了索引合并的优化方法
# 例子：

mysql> explain select * from teacher where id = 1 or teacher_no = 'T2010001'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: teacher
   partitions: NULL
         type: index_merge
possible_keys: PRIMARY,unx_teacher_no
          key: PRIMARY,unx_teacher_no
      key_len: 4,63
          ref: NULL
         rows: 2
     filtered: 100.00
        Extra: Using union(PRIMARY,unx_teacher_no); Using where
1 row in set, 1 warning (0.00 sec)
```



#### 8. range

```mysql
# 只检索给定范围的行，使用一个索引来选择行，key列显示使用了哪个索引
# 一般就是在你的where语句中出现between、<>、in等的查询。
# 例子：

explain select * from subject where id between 1 and 3;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211715715.png)



#### 9. index

```mysql
# Full index Scan，Index与All区别：index只遍历索引树，通常比All快
# 因为索引文件通常比数据文件小，也就是虽然all和index都是读全表，但index是从索引表中读取的，而all是从硬盘读的。
# 例子：

explain select id from subject;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211717253.png)



#### 10. ALL

```mysql
# Full Table Scan，将遍历全表以找到匹配行
# 例子：

explain select * from subject;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211718955.png)



### table字段

```bash
# 数据来自哪张表
```



### possible_keys字段

```bash
# 显示可能应用在这张表中的索引，一个或多个
# 查询涉及到的字段若存在索引，则该索引将被列出，但不一定被实际使用
```



### key字段

```bash
# 实际使用到的索引，如果为NULL，则没有使用索引
# 查询中若使用了覆盖索引（查询的列刚好是索引），则该索引仅出现在key列表
```



### key_len字段

```bash
# 表示索引中使用的字节数，可通过该列计算查询中使用的索引的长度
# 在不损失精确度的情况下，长度越短越好
# key_len显示的值为索引字段最大的可能长度，并非实际使用长度
# 即key_len是根据定义计算而得，不是通过表内检索出的
```



### ref字段

```bash
# 显示索引的哪一列被使用了，如果可能的话，是一个常数，哪些列或常量被用于查找索引列上的值
```



### rows字段

```bash
# 根据表统计信息及索引选用情况，大致估算出找到所需的记录所需读取的行数
```



### partitions字段

```bash
# 匹配的分区
# 查询进行匹配的分区，对于非分区表，该值为NULL。大多数情况下用不到分区。
```



### filtered字段

```bash
# 查询的表行占表的百分比，百分比越小，速度越快
```



### Extra字段

```bash
# 包含不适合在其它列中显示但十分重要的额外信息
```



#### 1. Using filesort

```mysql
# 说明MySQL会对数据使用一个外部的索引排序，而不是按照表内的索引顺序进行读取
# MySQL中无法利用索引完成的排序操作称为“文件排序”
# 例子：


explain select * from subject order by name;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211723511.png)



#### 2. Using temporary

```mysql
# 使用了临时表保存中间结果，MySQL在对结果排序时使用临时表，常见于排序order by 和分组查询group by
# 例子：


explain select subject.* from subject left join teacher on subject.teacher_id = teacher.id union select subject.* from subject right join teacher on subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211724685.png)



#### 3. Using index

```mysql
# 表示相应的select操作中使用了覆盖索引（Covering Index）,避免访问了表的数据行，效率不错！
# 如果同时出现using where，表明索引被用来执行索引键值的查找
# 如果没有同时出现using where，表明索引用来读取数据而非执行查找动作
# 例子：


explain select subject.* from subject,student_score,teacher where subject.id = student_id and subject.teacher_id = teacher.id;


# 备注：
# 覆盖索引：select的数据列只用从索引中就能够取得，不必读取数据行，MySQL可以利用索引返回select列表中的字段，而不必根据索引再次读取数据文件，即查询列要被所建的索引覆盖
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211726659.png)



#### 4. Using where

```mysql
# 使用了where条件
# 例子：

explain select subject.* from subject,student_score,teacher where subject.id = student_id and subject.teacher_id = teacher.id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211727335.png)



#### 5. Using join buffer

```mysql
# 使用了连接缓存
# 例子：
# 我用8.0不是这个提示，我用回5.7进行操作

explain select student.*,teacher.*,subject.* from student,teacher,subject;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211732280.png)



#### 6. impossible where

```mysql
# where子句的值总是false，不能用来获取任何值 
# 例子：

explain select * from teacher where name = 'wangsi' and name = 'lisi';
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211730663.png)



#### 7. distinct

```mysql
# 一旦mysql找到了与行相联合匹配的行，就不再搜索了
# 例子：

explain select distinct teacher.name from teacher left join subject on teacher.id = subject.teacher_id;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211735181.png)



#### 8. Select tables optimized away

```mysql
# SELECT操作已经优化到不能再优化了（MySQL根本没有遍历表或索引就返回数据了）
# 例子：

explain select min(id) from subject;
```

![](https://figure-bed-1304788733.cos.ap-guangzhou.myqcloud.com/typora/202203211736001.png)

