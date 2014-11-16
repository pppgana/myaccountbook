CREATE TABLE PAYMETHOD (
	id INT auto_increment NOT NULL, 
	paymethod VARCHAR(256) NOT NULL, 
	INDEX(id)
);
CREATE TABLE METHOD_DETAIL (
	id INT auto_increment NOT NULL, 
	paymethod INT NOT NULL, 
	method_detail VARCHAR(256) NOT NULL,
	FOREIGN KEY(PAYMETHOD) REFERENCES PAYMETHOD(id), 
	INDEX(id)
);

CREATE TABLE EXPENSE (
	id INT auto_increment NOT NULL, 
	date DATE NOT NULL, 
	amount INT NOT NULL, 
	paymethod INT NOT NULL, 
	method_detail INT, 
	item INT NOT NULL, 
	spot GEOMETRY , 
	note_of_spot VARCHAR(256),
	FOREIGN KEY(paymethod) REFERENCES PAYMETHOD(id),
	FOREIGN KEY(method_detail) REFERENCES METHOD_DETAIL(id),
	INDEX(id)
);  
