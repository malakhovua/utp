# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is a **1C:Enterprise 8.3 configuration** dumped to XML files via "Выгрузить конфигурацию в файлы" (hierarchical format). The configuration is **УправлениеТорговымПредприятиемДляУкраины** (УТП, v1.2 for Ukraine), a customized fork of the standard 1C UTP trade management platform. The scripting language is Russian (`ScriptVariant=Russian`), and the application runs in **OrdinaryApplication** mode (not managed application mode).

There are no build/lint/test CLI commands — all compilation, loading, and testing is done inside the 1C:Enterprise Designer (Конфигуратор) by loading this XML dump into a 1C infobase.

**To load changes into 1C:** open the Конфигуратор → Конфигурация → Загрузить конфигурацию из файлов → point to this directory.

## Repository Structure

Each metadata object has a `.xml` file describing its schema and a same-named **directory** holding its source code and sub-objects:

```
ObjectType/
  ObjectName.xml          ← schema/metadata definition
  ObjectName/
    Ext/
      ObjectModule.bsl    ← object module (BSL source code)
      Form.bin            ← ordinary form binary (for Ordinary forms)
    Forms/
      FormName.xml        ← form metadata
      FormName/
        Ext/
          Form.xml        ← managed form layout XML
          Form/
            Module.bsl    ← managed form module (BSL)
```

Root-level `Ext/` contains: `SessionModule.bsl`, `OrdinaryApplicationModule.bsl`, `ExternalConnectionModule.bsl`.

## Customization Naming Convention

All custom additions to the base UTP configuration are prefixed with **`umk_`**. Never add objects without this prefix (they would be indistinguishable from standard platform objects). This applies to:
- CommonModules: `umk_Доработки` (server), `umk_ДоработкиКлиент` (client ordinary), `umk_ПолныеПрава` (server privileged), `umk_ПолныеПраваКлиент`, `umk_РаботаСДиалогами`, `umk_connector77`
- Catalogs, InformationRegisters, DataProcessors, Reports — all custom ones start with `umk_`
- The only exception is new **Documents** like `ЗаписьЖРОИГП` which follow the subject domain name without prefix

## Forms

The configuration has **mixed form mode**:
- `UseManagedFormInOrdinaryApplication=false` and `UseOrdinaryFormInManagedApplication=false`
- Most existing forms are **Ordinary** (`FormType=Ordinary`), stored as `Form.bin` binaries
- New forms being added should be **Managed** (`FormType=Managed`), named with the `УФ` suffix (e.g., `ФормаДокументаУФ`, `ФормаСпискаУФ`, `ФормаВыбораУФ`) and stored as `Form.xml`

### Managed Form XML Rules

**Document form** — `Attributes` section:
```xml
<Attribute name="Объект" id="1">
    <Type><v8:Type>cfg:DocumentObject.ИмяДокумента</v8:Type></Type>
    <MainAttribute>true</MainAttribute>
    <SavedData>true</SavedData>
</Attribute>
```

**List/Choice forms** — `Attributes` section uses `DynamicList`, not `DocumentList`:
```xml
<Attribute name="Список" id="1">
    <Type><v8:Type>cfg:DynamicList</v8:Type></Type>
    <MainAttribute>true</MainAttribute>
    <Settings xsi:type="DynamicList">
        <ManualQuery>false</ManualQuery>
        <DynamicDataRead>true</DynamicDataRead>
        <MainTable>Document.ИмяДокумента</MainTable>
        ...
    </Settings>
</Attribute>
```

**Standard attribute data paths use English names:** `Объект.Date`, `Объект.Number`, `Список.Date`, `Список.Number` (not the Russian synonyms).

## Adding a New Document

1. Create `Documents/ИмяДокумента.xml` — full metadata XML with all `<InternalInfo>` UUIDs (use `python3 -c "import uuid; print(uuid.uuid4())"` to generate)
2. Create directory `Documents/ИмяДокумента/Forms/` and form subdirectories
3. Create form `.xml` metadata files and `Ext/Form.xml` layout files
4. Create empty `Ext/ObjectModule.bsl` and `Ext/Form/Module.bsl` files
5. Register in `Configuration.xml` by adding `<Document>ИмяДокумента</Document>` in **Cyrillic alphabetical order** within the `<ChildObjects>` section

**Cyrillic alphabet order** (п before р, so Запись < Зарплата): а б в г д е ж з и й к л м н о **п р** с т у ф х ц ч ш щ ъ ы ь э ю я

## Key Custom Modules

| Module | Context | Purpose |
|---|---|---|
| `umk_Доработки` | Server+ExternalConn | Core custom server logic, utility functions exported for use by all other custom code |
| `umk_ДоработкиКлиент` | ClientOrdinary | Client-side counterpart |
| `umk_ПолныеПрава` | Server Privileged | Privileged operations (session params, access rights); called from `SessionModule.bsl` |
| `umk_connector77` | Server+ExternalConn | Integration adapter wrapping `umk_Доработки` for 1C 7.7 external connections |

## Integration Points

- **1C 7.7 integration**: `umk_connector77` module + DataProcessors `umk_ЗагрузкаДанныхИз1С77_Склад`
- **Exchange plans**: `ОбменССайтомЗаказами/Товарами` (web store), `ОбменУправлениеТорговымПредприятиемРозничнаяТорговля` (retail), `umk_ПланОбменаУНФ`
- **Scheduled jobs**: `umk_ПровестиОтложенныеДокументы` (deferred posting), standard exchange/full-text-search jobs
- **EDIN** (electronic document exchange): `Controller_EDIN`, `EDIN_connect` modules + `EDIN_sessions` information register

##Правила написання коду

- Всі змінні коментарі пишимо російською мовою.
- використовувати стиль написання коду для керованих форм 1с 8.3 
- код має бути стантартизований під код УТП. Дивитися документ - РеализацияТоваровУслуг
- При перенесенні типів реквізитів та логіки, враховувати що в 1с77 немає типу булева. Замість булево 0 1. В УТП міняємо тип число на булево. 

##При закінченні завдання комітити та пушити зміни

##Версія платформи длч проєкту 1С:Предприятие 8.3 (8.3.18.1483)

### Comments
Add comments at the end of a block for conditions, loops, procedures, functions. At the end of specific variables. Edits you make with the mark - // + claude

##Припереносенні функціонала з конфігураціїї 1с 77
- беремо дані з каталогу /home/alex/Documents/My_projects/conf_old_1c77

## TODO

- [x]  Додати подсистему  - Термообработка
- [x]  Всі створені об'єкти в рамках цього завдання додаємо в подсистему Термообработка
- [x]  В конфігурації conf_old_1c77 Справочник ТМЦ форма справочника, слой Термообработка. Для всіх реквізитів форми на цьому слоє створити однойменні справочники та Перечисления . Всі реквізити яких повторити. 
- [x]  Справачник Номенклатура. Додати однойменні реквізити як на форми ТМЦ в слое Термообработка. також додати  табличнуючасть з реквизитами як таблиця на формі ТМЦ слоя Термообработка

- [x]  Аналогічно до пункти 4. для документа ЗаписьЖРОИГП, Зробити те саме для всіх реквізитів, окрім тих щопідходять за смістом контексту УТП. Виправити типи та додати нові об'єкти конфігурції, при необхідності. в 1с77 ТМЦ - це Номенклатура в УТП. тут без змін. Звірити программний код модуля та модуля форми.  однойменного докумена 1с77 -ЗаписьЖРОИГП. Перекласти логіку коду 1с 77 на логіку коди 1с8.3. Сформувати всі процедури та функції (друк, проведення і т.п.), використовувати стиль написання коду для керованих форм 1с  
- [x]  1с платформа тут - C:\Program Files\1cv8\8.3.18.1483\bin
База тут - Srvr="127.0.0.1";Ref="utp_dev";
потрібен скрипт для віндовс, що запустить стягування з репозиторія зміни та запустить завантаження конфігураціїї з файлів в каталозі 
-C:\utp
- [x]  Напиши батнік для вінди в проєкті. Щоб він автоматично вивантажував конфігурацію в файли з конфігуратора, коммітив та пушив 
- [x] Звірити структуру Владельцев Справочников в конфігурації 1с77 та УТП. При необхідності повторити в УТП.
- [x] Звірити логіку алгоритмів форм Справочников, та повторити в УТП форми Справочников та форми їх списків та форми Вибіру. 
- [x]  ЗаписьЖРОИГП - замість ПН (тип ПоступлениеТоваровУслуг) має бути документ ОтчетПроизводстваЗаСмену. Назву реквізита змінити. 
- [x]  В модулє об'єтка ЗаписьЖРОИГП розробити процедуру заповнення на підставі ОтчетПроизводстваЗаСмену. ОбработкаЗаполнения. Взяти логіку заповнення з 1с77(на підставі ПН), але стиль коду має бути стантартизований під код УТП. Дивитися приклад документ - РеализацияТоваровУслуг
- [x] Створити аналоги документів: 1. УМК_НачалоТермообработки 2. УМК_ЗагрузкаКамеры  В УТП без префіксів УМК_ 
- [x] НачалоТермообработки - Повторити логіку модуря об'єкта, повторити логіку модуля форми 1с77, вивести текстову декорацію ВозвратПрограмма(), враховуючи специфіку керованих форм та мову 1с8.3
- [x] ЗагрузкаКамеры - повторити логіку модуля форми 1с77, вивести текстову декорацію ТекстМногоРам, ВернутьКвоРам, "К-во рам в камере : " + КамераТермообработки.КоличествоРам, "Итого к-во"+Формат(Итог("Кво"),"Ч12.2"), враховуючи специфіку керованих форм та мову 1с8.3
- [x] Перевірити модулі форм довідників в 1с77  підсистеми - термообработка. Додати в довідники Термообработки УТП всю логіку форм, елементів, написів, декорацій, та Команди.  

