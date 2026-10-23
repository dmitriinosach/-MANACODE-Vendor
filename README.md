# [manacode] Vendor 0.1.4

## Русский

**Что нового**
- В узком окне цена продажи хлама уступает место починке и кошельку: сначала
  остаётся «хлам xN», затем только иконка. Полная сумма — в подсказке;
  при расширении окна подробности возвращаются.
- Если для вещи не хватает эмблем, подтверждение предлагает доступный у
  торговца обмен и покупку одним действием. Неполный план не тратит валюту.
- В окне обмена количество не сбрасывается молча до доступного: окно объясняет
  нехватку и обновляет расчёт при изменении запаса валюты.
- Возврат вещи за эмблемы, честь или очки арены снова спрашивает подтверждение
  до продажи. Работает при правом клике по вещи в сумке и при перетаскивании на
  прилавок; «Нет» отменяет возврат. Предупреждения о лимите чести и арены —
  штатные, закрытие торговца убирает незавершённое подтверждение.
- Возврат за баджи работает и на отдельно созданных кнопках Bagnon.
- На вкладке «Выкуп» правый клик по вещи в сумке не продаёт её торговцу.

**[manacode] Vendor — весь товар торговца в одном окне для WoW 3.3.5a.**

Делюсь очередной своей наработкой. Сделал аддон, чтобы не листать страницы
у торговцев и быстрее находить нужную вещь. Им уже пользуется небольшое число
игроков. Если людям зайдёт, буду дорабатывать дальше — по своим задачам
и вашим отзывам.

Вместо страниц по десять предметов Vendor показывает весь ассортимент
прокручиваемым списком. Окно открывается само при разговоре с торговцем.

**Что полезного**

- Наборы экипировки собраны вместе: слоты строками, ступени улучшений рядом,
  короткие метки тиров и сезонов арены.
- Остальной товар группируется по типу, профессии или рангу репутации.
  Есть поиск по имени; на русском клиенте он понимает и неверную раскладку.
- Фильтры скрывают ненужное: чужой класс, неподходящую броню и характеристики,
  реагенты чужих профессий, устаревшие ранги, слабую еду и питьё.
- Видно, какие вещи уже есть в сумках, банке или на персонаже.
- Подсказка «Для чего» объясняет, какому заклинанию или рецепту нужен реагент,
  и учитывает записанные профессии других персонажей. После установки откройте
  окно профессии, чтобы аддон запомнил рецепты.
- Покупка пачками x5, x20 и x100 показывает количество и общую стоимость
  перед подтверждением.
- Цепочки обмена эмблем показывают весь путь до выбранной валюты или вещи.
  Аддон использует промежуточные эмблемы, которые уже есть, и меняет только
  недостающее. Все нужные обмены должны быть доступны у открытого торговца.
- Продажа серого хлама с подтверждением, отдельная вкладка выкупа,
  починка за свои деньги или из гильдейского банка.
- Возврат вещи за баджи со штатным вопросом «Да / Нет», в том числе из Bagnon.
  Если продать нужный реагент или предмет задания, аддон предупредит и напомнит
  про выкуп.
- Плитки или строки, два оформления, изменение размера и масштаба.
  Размер окна запоминается отдельно для каждого торговца.

**Установка и обновления**

Скачать аддон можно на [странице релизов](https://github.com/dmitriinosach/-MANACODE-Vendor/releases).
Распакуйте папку `ManaCode_Vendor` в `Interface\AddOns` и полностью перезапустите
клиент после первой установки. При обновлении с 0.1.3 достаточно `/reload`.

Есть и моя [обновлялка ManacodeUpdate — скачать](https://github.com/dmitriinosach/-MANACODE-Update/releases/latest).
Через неё можно скачивать все мои аддоны из каталога и автоматически обновлять
установленные. Vendor в каталоге уже есть, так что вручную скачивать каждый
новый архив не обязательно.

**Команды**

- `/vendor` — состояние аддона.
- `/vendor off` / `/vendor on` — вернуть штатное окно / включить Vendor.
- `/vendor reset` — сбросить сохранённые размеры окон.
- `/vendor theme vanilla` / `/vendor theme flat` — выбрать оформление.

Клиент: **WoW 3.3.5a, build 12340**. Интерфейс на русском и английском.
Обратная связь: [GitHub Issues](https://github.com/dmitriinosach/-MANACODE-Vendor/issues)
или [Discord](https://discord.gg/hpTkJCJbwn).

## English

**What’s new**
- Narrow windows shorten the junk sale summary to a count or just its button.
  The full sale value stays in the tooltip; widening the window restores the details.
- When an item needs more emblems than you currently hold, the confirmation can
  exchange the missing currency and buy the item in one action, using exchanges
  offered by the current merchant. Incomplete plans do not spend currency.
- The exchange quantity no longer silently drops to the available amount. The
  dialog explains shortages and updates when your currency balance changes.
- Refunding purchases made with emblems, honor or arena points shows the stock
  confirmation before the item is sold, including right-clicks in Bagnon and
  dragging items onto the merchant. Declining cancels the refund; currency cap
  warnings remain in place, and closing the merchant clears the pending dialog.
- Right-clicking an item in your bags while on the Buyback tab no longer sells it.

**[manacode] Vendor — the entire merchant stock in one window for WoW 3.3.5a.**

Sharing another personal project of mine. I made this addon to spend less time
flipping through merchant pages and find the item I need more easily. A few
people are already using it. If others find it useful, I'll keep developing it,
based on my own needs and your feedback.

Vendor replaces pages of ten items with one scrollable list of everything the
merchant sells. It opens automatically when you talk to a merchant.

**Useful features**

- Gear sets stay together: one row per equipment slot, upgrade tiers side by
  side, with short tier and arena season labels.
- Other goods are grouped by type, profession or reputation rank. Name search
  also handles the wrong keyboard layout on a Russian client.
- Filters hide items you do not need: other classes' gear, unsuitable armor and
  stats, other professions' reagents, old ranks, and low-level food and drinks.
- See which items you already own in your bags, bank or equipped slots.
- A “Used for” tooltip explains which spell or recipe needs a reagent, including
  recorded professions on your other characters. Open your profession window
  after installation so the addon can record your recipes.
- Bulk purchases of x5, x20 and x100 show the quantity and total cost before
  you confirm.
- Emblem exchange chains show the route to a currency or an item. They use
  intermediate emblems you already hold and exchange only the missing amount.
  Every required exchange must be offered by the merchant you have open.
- Sell gray junk with confirmation, use a separate Buyback tab, and repair
  with your own money or guild bank funds.
- Purchases made with emblems can be refunded with the stock Yes / No prompt,
  including from Bagnon. Selling a useful reagent or quest item triggers a
  warning and a reminder to buy it back.
- Tile or row layouts, two themes, resizing and scaling. Window size is
  remembered separately for each merchant.

**Install and update**

Download the addon from the [releases page](https://github.com/dmitriinosach/-MANACODE-Vendor/releases).
Extract the `ManaCode_Vendor` folder into `Interface\AddOns` and restart the
client after the first installation. Updating from 0.1.3 only needs `/reload`.

You can also use my [ManacodeUpdate updater — download here](https://github.com/dmitriinosach/-MANACODE-Update/releases/latest).
It lets you download all of my addons listed in its catalog and automatically
update the ones you have installed. Vendor is already included, so you do not
need to download each new ZIP manually.

**Commands**

- `/vendor` — addon status.
- `/vendor off` / `/vendor on` — restore the stock window / enable Vendor.
- `/vendor reset` — reset saved window sizes.
- `/vendor theme vanilla` / `/vendor theme flat` — choose a theme.

Client: **WoW 3.3.5a, build 12340**. English and Russian UI.
Feedback: [GitHub Issues](https://github.com/dmitriinosach/-MANACODE-Vendor/issues)
or [Discord](https://discord.gg/hpTkJCJbwn).
