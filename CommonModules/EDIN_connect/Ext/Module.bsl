//Возвращает SID сессии
Функция connect_api() Экспорт
	
	token = "";
	//Проверим наличие текущего токена
	token = session_token();
	
	Если ЗначениеЗаполнено(token) Тогда
		Возврат token
	КонецЕсли;
	
	ServerName = Константы.EDIN_serverName.Получить();
    usr = Константы.EDIN_usr.Получить();
	pw  = Константы.EDIN_pw.Получить();
	
	ssl = Новый ЗащищенноеСоединениеOpenSSL(
                Новый СертификатКлиентаWindows(
                                СпособВыбораСертификатаWindows.Выбирать),
                Новый СертификатыУдостоверяющихЦентровWindows());  
				
	https = Новый HTTPСоединение(ServerName,,,,,5,ssl);
	 
	HTTP_Headers = Новый Соответствие();
	HTTP_Headers.Вставить("Content-Type", "application/x-www-form-urlencoded");
	
	АдресРесурса = "/api/authorization/hash";
	
	http_request = Новый HTTPЗапрос(АдресРесурса, HTTP_Headers);
	
	//request body
    json_string = "&email="+usr+"&password="+pw;
	
	http_request.УстановитьТелоИзСтроки("mData="+json_string,,ИспользованиеByteOrderMark.Использовать);
    
	
	Попытка
		response = https.ОтправитьДляОбработки(http_request);
		//token = response.ПолучитьТелоКакСтроку();
		
		ЧтениеJSON = Новый ЧтениеJSON;
		ЧтениеJSON.УстановитьСтроку(response.ПолучитьТелоКакСтроку());
		
		Данные = ПрочитатьJSON(ЧтениеJSON, Ложь);
		token = Данные.SID;
		//Запишем SID в регитр
		Запись = РегистрыСведений.EDIN_sessions.СоздатьМенеджерЗаписи();
		Запись.token = token;
		Запись.Период = ТекущаяДата();
		Запись.Записать(Истина);
	Исключение
		Сообщить(ОписаниеОшибки());
	КонецПопытки;
	
	Возврат token
	
	
Конецфункции

// method - адрес ресурса
// HTTP_Headers - Заголовки, тип Соответствие. 
Функция api_request(method,  HTTP_Headers = Неопределено, body_request = неопределено)Экспорт
	
	ServerName = Константы.EDIN_serverName.Получить();
	result = Неопределено;
	
	//токен сессии
	token = EDIN_connect.connect_api();
	
	Если НЕ ЗначениеЗаполнено(token) Тогда
		Возврат result
	КонецЕсли;
	
	//тип соединения https
	ssl = Новый ЗащищенноеСоединениеOpenSSL(
                Новый СертификатКлиентаWindows(
                                СпособВыбораСертификатаWindows.Выбирать),
                Новый СертификатыУдостоверяющихЦентровWindows());  
				
	//само соединение			
	https = Новый HTTPСоединение(ServerName,,,,,5,ssl);
	
		
	//Заголовки
	Если HTTP_Headers = НЕопределено Тогда
		HTTP_Headers = Новый Соответствие();
	КонецЕсли;
	//Заголовок проверки сессии.
	HTTP_Headers.Вставить("Authorization", token);
	
	//Запрос  по методу с заголовками.
	http_request = Новый HTTPЗапрос(method, HTTP_Headers);
	
	//Если медот POST
	Если ЗначениеЗаполнено(body_request) Тогда
		http_request.УстановитьТелоИзСтроки(body_request,,ИспользованиеByteOrderMark.Использовать);
		result = https.ОтправитьДляОбработки(http_request);
		//result = https.ОтправитьДляОбработки(http_request);
    //Иначе метод GET
    Иначе
	   result = https.Получить(http_request);	
	КонецЕсли;
	
	Возврат   result
	
КонецФункции

Функция check_session () экспорт
	
	active = Ложь;
	
	request = EDIN_connect.api_request("/api/auth_check");
	active = request.КодСостояния = 200;
	
	Возврат active
	
КонецФункции

//токен сессии хранится не больше 20 мин.
//Если время не истекло то берем его. 
Функция session_token() экспорт
	
	token = "";
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	EDIN_sessionsСрезПоследних.Период,
	|	EDIN_sessionsСрезПоследних.token
	|ИЗ
	|	РегистрСведений.EDIN_sessions.СрезПоследних(&Период, ) КАК EDIN_sessionsСрезПоследних";
	
	Запрос.УстановитьПараметр("Период", ТекущаяДата());
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Если Выборка.Следующий() Тогда
		
		Если (ТекущаяДата() - Выборка.Период) < 18*60 //18 мин.
			Тогда token = Выборка.token;
		Иначе //Удалим все записи.
			Набор = РегистрыСведений.EDIN_sessions.СоздатьНаборЗаписей();
			Набор.Записать();
		КонецЕсли;	
	КонецЕсли;
	
	Возврат token
	
КонецФункции
