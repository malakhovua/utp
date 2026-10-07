//Получает данные документов клиента из базы 1с77
//
Функция ПолучитьДанныДокумента(Путь, Метод, НомерДокумента, Дата1, Дата2, КодКонтрагентаГруппы) Экспорт
	
	HTTP_Structure = ОбщегоНазначенияСерверWEB.ПолучитьHTTPСоединение("1с77_work");
	
	Если HTTP_Structure = Неопределено
		Тогда
		Возврат Неопределено 
	КонецЕсли;
	
	HTTP = HTTP_Structure.HTTP;
	base = HTTP_Structure.СтруктураURI.base;
	
	СтрокаЗапроса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку("/%1/documents/%2",base, Путь);
	
	//Реализация на стороне сервера:
	//
	//get '/work/orders/by_number/:doc_number/:date' do
	//  @V7.GetOrderByNumber(params[:doc_number], v7_date(params[:date]))
	//end
	//
	//get '/work/orders/by_period/:date_1/:date_2' do
	//  @V7.GetOrderByPeriod(v7_date(params[:date_1]), v7_date(params[:date_2]))
	//end
	//
	//get '/work/orders/by_client_group/:code/:date' do
	//  @V7.GetOrderByClientGroupCode(params[:code], v7_date(params[:date]))
	//end
	//
	//get '/work/orders/by_client_group_period/:code/:date_1/:date_2' do
	//  GetOrderByClientGroupCodePeriod(params[:code], v7_date(params[:date_1]),v7_date(params[:date_2]))
	//end
	
	Если  Метод = "GetOrderByNumber" Тогда
		СтрокаЗапроса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(СтрокаЗапроса + "/%1/%2/%3","by_number", НомерДокумента,Дата1);	
	ИначеЕсли Метод = "GetOrderByPeriod" Тогда
		СтрокаЗапроса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(СтрокаЗапроса + "/%1/%2/%3","by_period", Дата1,Дата2);
	ИначеЕсли Метод = "GetOrderByClientGroupCode" Тогда
		СтрокаЗапроса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(СтрокаЗапроса + "/%1/%2/%3","by_client_group", КодКонтрагентаГруппы,Дата1);
	ИначеЕсли Метод = "GetOrderByClientGroupCodePeriod" Тогда
		СтрокаЗапроса = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(СтрокаЗапроса + "/%1/%2/%3/%4","by_client_group_period", КодКонтрагентаГруппы,Дата1,Дата2);
	КонецЕсли;
	
	http_request = Новый HTTPЗапрос(СтрокаЗапроса);
	
	Попытка
		Результат = HTTP.Получить(http_request);
	Исключение
		Сообщить("Сервер не отвечает.");		
		Возврат Неопределено
	КонецПопытки;	
	
	Если Не Результат.КодСостояния = 200 Тогда
		Сообщить("Ошибка ответа сервера.");
		Возврат  Неопределено
	КонецЕсли;
	
	response = Результат.ПолучитьТелоКакСтроку();
	
	Если Не ЗначениеЗаполнено(response) Тогда
		Возврат Неопределено
	КонецЕсли;
	
	Если response = "ERROR" Тогда
		Сообщить("Ошибка ответа сервера. ERROR Execute file");
		Возврат  Неопределено
	КонецЕсли;
	
	Возврат response
	
КонецФункции