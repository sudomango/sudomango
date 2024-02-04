// Программный модуль документа РеализацияТоваров.

Процедура ОбработкаЗаполнения(ДанныеЗаполнения, СтандартнаяОбработка)
    // Ввод на основании документа "ЗаказКлиента".
	Если ТипЗнч(ДанныеЗаполнения) = Тип("ДокументСсылка.ЗаказКлиента") Тогда
		// Заполнение шапки документа.
		ИтоговаяСумма = ДанныеЗаполнения.ИтоговаяСумма;
		Клиент = ДанныеЗаполнения.Клиент;
		Склад = ДанныеЗаполнения.Склад;
        // Заполнение табличной части документа.
		Для Каждого ТекСтрокаТовары Из ДанныеЗаполнения.Товары Цикл
			НоваяСтрока = Товары.Добавить();
			НоваяСтрока.Количество = ТекСтрокаТовары.Количество;
			НоваяСтрока.Сумма = ТекСтрокаТовары.Сумма;
			НоваяСтрока.Товар = ТекСтрокаТовары.Товар;
			НоваяСтрока.Цена = ТекСтрокаТовары.Цена;
		КонецЦикла;
	КонецЕсли;
КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, Режим)
    
    Движения.Взаиморасчеты.Записывать = Истина;
    Движения.Продажи.Записывать = Истина;
    Движения.ОстаткиТоваров.Записывать = Истина;
    Движения.РегистрБухУчета.Записывать = Истина;
    Движения.СебестоимостьТоваровРасчет.Записывать = Истина;
    
    СебестоимостьСловарь = РасчетСебестоимостиТоваров();
    // Эта переменная нужна для заполнения регистра бухгалтерии в дальнейшем = итоговая себестоимость товаров документа.
    СебестоимостьВсегоДокументаСумма = 0;
    
    Для Каждого ТекСтрокаТовары Из Товары Цикл
        // Если себестоимость для товара не найдена, значит данный товар никогда не закупался.
        // Так как документ "Поступление товаров" делает запись прихода в регистре "СебестоимостьТоваровРасчет".
        
        Себестоимость = СебестоимостьСловарь[ТекСтрокаТовары.Товар];
        Если Себестоимость = Неопределено Тогда
            Отказ = Истина;
            Сообщить("Похоже, вы пытаетесь продать ранее незакупленный товар.");
            Возврат;
        КонецЕсли;
        
        СебестоимостьПродажи = Себестоимость * ТекСтрокаТовары.Количество;
        СебестоимостьВсегоДокументаСумма = СебестоимостьВсегоДокументаСумма + СебестоимостьПродажи;
        
        // Регистр Взаиморасчеты Приход
        Движение = Движения.Взаиморасчеты.Добавить();
        Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
        Движение.Период = Дата;
        Движение.Контрагент = Клиент;
        Движение.Сумма = ТекСтрокаТовары.Сумма;        
        
        // Регистр Продажи 
        Движение = Движения.Продажи.Добавить();
        Движение.Период = Дата;
        Движение.Клиент = Клиент;
        Движение.Номенклатура = ТекСтрокаТовары.Товар;
        Движение.Количество = ТекСтрокаТовары.Количество;
        Движение.Выручка = ТекСтрокаТовары.Сумма;
        Движение.СебестоимостьПродаж = СебестоимостьПродажи;
        
        // Регистр ОстаткиТоваров Расход
        Движение = Движения.ОстаткиТоваров.Добавить();
        Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
        Движение.Период = Дата;
        Движение.Номенклатура = ТекСтрокаТовары.Товар;
        Движение.Склад = Склад;
        Движение.Количество = ТекСтрокаТовары.Количество;
        
        // Регистр СебестоимостьТоваровРасчет Расход
        Движение = Движения.СебестоимостьТоваровРасчет.Добавить();
        Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
        Движение.Период = Дата;
        Движение.Номенклатура = ТекСтрокаТовары.Товар;
        Движение.Количество = ТекСтрокаТовары.Количество;
        // Расчёт идёт по старой себестоимости, которая была до проведения документа.
        Движение.Сумма = СебестоимостьПродажи;
    КонецЦикла;
    
    // Регистр РегистрБухУчета
    Движение = Движения.РегистрБухУчета.Добавить();
    Движение.СчетДт = ПланыСчетов.СчетаБухгалтерскогоУчета.Покупатели;
    Движение.СчетКт = ПланыСчетов.СчетаБухгалтерскогоУчета.Выручка;
    Движение.Период = Дата;
    Движение.Сумма = ИтоговаяСумма;
    
    Движение = Движения.РегистрБухУчета.Добавить();
    Движение.СчетДт = ПланыСчетов.СчетаБухгалтерскогоУчета.Себестоимость;
    Движение.СчетКт = ПланыСчетов.СчетаБухгалтерскогоУчета.Товары;
    Движение.Период = Дата;
    Движение.Сумма = СебестоимостьВсегоДокументаСумма;
    
КонецПроцедуры

Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
    Если НЕ КонтрольОстатков() Тогда
        Отказ = Истина;
        Сообщить("Недостаточное количество товара!");
        Возврат;
    КонецЕсли;
    
    ИтогСумма = 0;
    Для Каждого ТоварСтрока Из Товары Цикл
        ИтогСумма = ИтогСумма + ТоварСтрока.Сумма;
    КонецЦикла;
    ИтоговаяСумма = ИтогСумма;
КонецПроцедуры

Функция КонтрольОстатков()
    Результат = Истина;
    СкладТовара = Склад;
    
    // Так как в табличной части могут быть представлены одинаковые номенклатурные позиции несколько раз,
    // а нам нужно сравнивать с регистром остатков товаров их общее количество (а не по отдельности),
    // то необходимо создать небольшую вспомогательную таблицу, где будем хранить сгруппированное количество.
    ВыгрузкаКоличество = Товары.Выгрузить(,"Товар, Количество");
    ВыгрузкаКоличество.Свернуть("Товар", "Количество");
    
    Для Каждого СтрокаТЧ Из Товары Цикл
        Товар = СтрокаТЧ.Товар;
        
        Отбор = Новый Структура;
        Отбор.Вставить("Номенклатура", Товар);
        Отбор.Вставить("Склад", СкладТовара);
        // Вместо стандартного реквизита Дата используем метод МоментВремени() = получить актуальное время документа.
        // Таким образом, можно проверять остатки даже у документов с неоперативным проведением.
        ДанныеИзРегистра = РегистрыНакопления.ОстаткиТоваров.Остатки(МоментВремени(), Отбор, "Номенклатура, Склад");
        Если ДанныеИзРегистра.Количество() > 0 Тогда
            ОстатокТовара = ДанныеИзРегистра[0].Количество;
        Иначе
            ОстатокТовара = 0;
        КонецЕсли;
        
        // Сравниваем со значением в регистре остатков количество, просуммированное по одинаковым товарным позициям.
        СтрокаТовара = ВыгрузкаКоличество.Найти(Товар, "Товар");
        ОбщееКоличество = СтрокаТовара.Количество;
        
        Если ОбщееКоличество > ОстатокТовара Тогда
            Результат = Ложь;
        КонецЕсли;
    КонецЦикла;
    Возврат Результат;
КонецФункции

Функция РасчетСебестоимостиТоваров()
    // Вычисляем себестоимость из регистра накопления сразу по всем номенклатурным позициям в документе.
    Запрос = Новый Запрос;
    Запрос.Текст = "ВЫБРАТЬ
                   |    СебестоимостьТоваровРасчетОстатки.Номенклатура.Ссылка КАК Номенклатура,
                   |    СебестоимостьТоваровРасчетОстатки.КоличествоОстаток КАК Количество,
                   |    СебестоимостьТоваровРасчетОстатки.СуммаОстаток КАК СуммаЗакупки
                   |ИЗ
                   |    РегистрНакопления.СебестоимостьТоваровРасчет.Остатки(
                   |            &МоментВремени,
                   |            Номенклатура В
                   |                (ВЫБРАТЬ
                   |                    РеализацияТоваровТовары.Товар КАК Товар
                   |                ИЗ
                   |                    Документ.РеализацияТоваров.Товары КАК РеализацияТоваровТовары
                   |                ГДЕ
                   |                    РеализацияТоваровТовары.Ссылка = &ДокументПродажи)) КАК СебестоимостьТоваровРасчетОстатки";
    // В качестве документа продажи устанавливаем текущий документ.
    Запрос.УстановитьПараметр("ДокументПродажи", Ссылка);
    Запрос.УстановитьПараметр("МоментВремени", МоментВремени());
    
    РезультатЗапроса = Запрос.Выполнить();
    Выборка = РезультатЗапроса.Выбрать();
    
    // Стоит обратить внимание, что функция возвращает не скалярный тип данных, а соответствие.
    СебестоимостьСловарь = Новый Соответствие;
    
    Пока Выборка.Следующий() Цикл
        Если Выборка.Количество > 0 Тогда
            СебестоимостьТовара = Выборка.СуммаЗакупки / Выборка.Количество;
        Иначе
            СебестоимостьТовара = 0;
        КонецЕсли;
        СебестоимостьСловарь.Вставить(Выборка.Номенклатура, СебестоимостьТовара);
    КонецЦикла;
    
    Возврат СебестоимостьСловарь;
КонецФункции