# Единая база всех пользовательских текстов игры.
# Чтобы добавить новую фразу: добавьте одинаковый ключ в ru, en и es,
# затем запрашивайте её через Localization.get_text("ключ").
extends Node

signal language_changed(language_code: String)

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "interface"
const SETTINGS_KEY := "language"
const DEFAULT_LANGUAGE := "ru"
const SUPPORTED_LANGUAGES: Array[String] = ["ru", "en", "es"]
const LANGUAGE_NAMES := {
	"ru": "Русский",
	"en": "English",
	"es": "Español",
}

const TEXTS := {
	"ru": {
		"ui.inventory": "ИНВЕНТАРЬ",
		"ui.active": "АКТИВНЫЕ",
		"ui.items": "ПРЕДМЕТЫ",
		"ui.pause": "ПАУЗА",
		"ui.resume": "ПРОДОЛЖИТЬ",
		"ui.quit": "ВЫЙТИ ИЗ ИГРЫ",
		"ui.language": "ЯЗЫК",
		"ui.dialogue_placeholder": "Текст реплики",
		"ui.dialogue_footer": "[E] Следующая реплика     [Esc] Закрыть",
		"brand.subtitle": "ГАРАЖНАЯ ПИВОВАРНЯ",
		"interaction.stand": "E — встать с лавочки",
		"interaction.charge_release": "Q — отпусти для сильного броска",
		"interaction.place_throw": "Q — поставить / удерживать для броска",
		"interaction.pickup": "E — взять: %s",
		"interaction.generic": "E — взаимодействовать",
		"message.beer_drunk": "ПИВО ВЫПИТО",
		"message.item_fell": "ПРЕДМЕТ ВЫПАЛ ИЗ РУК",
		"item.generic": "предмет",
		"item.mug": "пивная кружка",
		"item.mug_beer": "кружка с пивом",
		"item.bucket_empty": "пустое ведро",
		"item.bucket_water": "ведро с водой",
		"item.crate": "коробка",
		"item.toolbox": "ящик с инструментами",
		"item.tool": "инструмент",
		"item.tire": "шина",
		"item.extinguisher": "огнетушитель",
		"item.malt_sack": "мешок солода",
		"item.hops_crate": "ящик хмеля",
		"item.yeast_box": "коробка дрожжей",
		"item.raw_barrel": "бочка сырья",
		"item.garden_seed": "семена солода",
		"item.garden_harvest": "солод",
		"item.flower": "Цветочек",
		"item.duck": "Утка",
		"ingredient.malt": "Солод",
		"ingredient.hops": "Хмель",
		"ingredient.yeast": "Дрожжи",
		"bench.sit": "E — сесть на лавочку",
		"garden.seed_sign": "СЕМЕНА ДЛЯ ГРЯДКИ",
		"garden.empty": "ГРЯДКА — возьми семечко со столика",
		"garden.plant": "E — посадить семечко",
		"garden.planted": "СЕМЕЧКО ПОСАЖЕНО",
		"garden.growing": "РАСТЁТ — %d%%",
		"garden.harvest": "E — собрать урожай",
		"garden.harvested": "УРОЖАЙ СОБРАН",
		"vat.dry": "ЧАН — сначала налей воду из ведра",
		"vat.ready": "ЧАН — добавляй ингредиенты",
		"vat.add_water": "E — вылить воду в чан",
		"vat.need_water": "Сначала наполни ведро у водокачки",
		"vat.fill_mug": "E — налить пиво в кружку",
		"mug.drink": "E — выпить пиво",
		"brew.need_water": "СНАЧАЛА НАЛЕЙ ВОДУ В ЧАН",
		"brew.enough_ingredient": "Этого ингредиента уже достаточно",
		"brew.added": "Добавлено: %s",
		"brew.ready": "ПИВО ГОТОВО!",
		"brew.flower_no_surprise": "Цветок исчез... но сюрприз не назначен",
		"brew.duck_surprise": "ЦВЕТОК?! ЧАН ВЫПЛЮНУЛ УТКУ! КРЯ!",
		"brew.first_brew": "Сначала свари пиво",
		"brew.mug_full": "Кружка уже полная",
		"brew.mug_filled": "Кружка наполнена пивом",
		"brew.water_enough": "В чан уже налито достаточно воды",
		"brew.water_added": "Вода налита в чан — добавляй ингредиенты",
		"brew.water_yes": "ЗАЛИТА",
		"brew.water_no": "НЕТ",
		"brew.status": "Варка пива — вода: %s\nСолод %d/%d   Хмель %d/%d   Дрожжи %d/%d\nE — взять   Q — поставить / удерживать для броска",
		"brew.complete": "Рецепт завершён",
		"pump.prompt": "ВОДОКАЧКА — возьми ведро и нажми E",
		"pump.bucket_full_message": "ВЕДРО УЖЕ ПОЛНОЕ",
		"pump.bucket_filled_message": "ВЕДРО НАПОЛНЕНО ВОДОЙ",
		"pump.bucket_full": "Ведро уже полное",
		"pump.fill": "E — наполнить ведро водой",
		"light.label": "СВЕТ",
		"light.enabled": "СВЕТ ВКЛЮЧЁН",
		"light.disabled": "СВЕТ ВЫКЛЮЧЕН",
		"light.turn_off": "E — выключить свет",
		"light.turn_on": "E — включить свет",
		"gate.label": "ВОРОТА",
		"gate.open": "E — открыть ворота",
		"gate.close": "E — закрыть ворота",
		"gate.opening": "ВОРОТА ОТКРЫВАЮТСЯ",
		"gate.closing": "ВОРОТА ЗАКРЫВАЮТСЯ",
		"gate.close_outside": "Чтобы закрыть ворота, выйди наружу",
		"gallery.reset_label": "СБРОС",
		"gallery.goal": "СБЕЙ 3 МИШЕНИ",
		"gallery.complete": "ВСЕ СБИТЫ!",
		"gallery.restored": "МИШЕНИ ВОССТАНОВЛЕНЫ",
		"gallery.reset": "E — восстановить мишени",
		"guide.world_label": "ГИД",
		"guide.name": "Гид",
		"guide.prompt": "E — поговорить: %s",
		"guide.no_lines": "У меня пока нет реплик. Добавь их в Inspector.",
		"guide.line_1": "Привет! Я помогу тебе сварить первое пиво.",
		"guide.line_2": "Наведи прицел на ингредиент и нажми E, чтобы взять его.",
		"guide.line_3": "Для рецепта нужны две порции солода, один хмель и одни дрожжи.",
		"guide.line_4": "Подойди к чану, наведи на него прицел и нажми E, чтобы бросить ингредиент.",
		"guide.line_5": "Счётчик слева показывает, сколько ингредиентов уже находится в чане.",
		"guide.line_6": "Если предмет застрял, подними его снова и брось немного выше края чана.",
		"guide.line_7": "Когда все четыре ингредиента окажутся в чане, пиво будет готово!",
		"roulette.zero": "ЗЕРО",
		"roulette.red": "КРАСНОЕ",
		"roulette.black": "ЧЁРНОЕ",
		"roulette.unknown": "НЕИЗВЕСТНО",
		"roulette.title": "РУЛЕТКА",
		"roulette.zero_button": "ЗЕРО  [E]",
		"roulette.red_button": "КРАСНОЕ  [E]",
		"roulette.black_button": "ЧЁРНОЕ  [E]",
		"roulette.idle": "ВЫБЕРИ СТАВКУ: ЗЕРО / КРАСНОЕ / ЧЁРНОЕ",
		"roulette.prompt_zero": "E — поставить на ЗЕРО",
		"roulette.prompt_red": "E — поставить на КРАСНОЕ",
		"roulette.prompt_black": "E — поставить на ЧЁРНОЕ",
		"roulette.prompt_bet": "E — сделать ставку",
		"roulette.spinning_hover": "РУЛЕТКА — колесо крутится...",
		"roulette.result_hover": "РУЛЕТКА — выпало %d, %s: %s",
		"roulette.aim": "РУЛЕТКА — наведи прицел на цвет ставки",
		"roulette.won_short": "выигрыш",
		"roulette.lost_short": "не повезло",
		"roulette.already_spinning": "РУЛЕТКА УЖЕ КРУТИТСЯ...",
		"roulette.spinning": "СТАВКА: %s\nКРУТИМ...",
		"roulette.won": "ВЫИГРЫШ!",
		"roulette.lost": "НЕ ПОВЕЗЛО",
		"roulette.result": "ВЫПАЛО: %d — %s\n%s",
		"duck.sound": "КРЯ?!",
		"warehouse.sign": "СКЛАД ПИВНОГО СЫРЬЯ\nСОЛОД • ХМЕЛЬ • ДРОЖЖИ",
		"warehouse.buy_prompt": "купить 3 комплекта сырья за $20",
		"warehouse.instructions": "1. ЗАКУПКА СЫРЬЯ\nE — комплект солода, хмеля и дрожжей",
		"yard.title": "УЧЕБНАЯ ПИВОВАРНЯ\nсклад сырья → варка → упаковка → продажа → улучшения",
		"yard.buy_prompt": "купить 3 сырья за $20",
		"yard.buy_title": "1. ЗАКУПКА СЫРЬЯ",
		"yard.buy_description": "Деньги → солод / фрукты / сахар\nE: 3 сырья за $20",
		"yard.recipe_prompt": "открыть новый пивной рецепт",
		"yard.recipe_title": "5. ПИВНОЙ РЕЦЕПТ",
		"yard.recipe_description": "Сырьё + $30 → новый сорт\nРецепт повышает цену пива",
		"yard.upgrade_prompt": "улучшить оборудование",
		"yard.upgrade_title": "6. УЛУЧШЕНИЯ",
		"yard.upgrade_description_old": "Деньги → оборудование\nКачество и Tier растут",
		"yard.upgrade_description": "Деньги → оборудование\nКачество растёт, варка быстрее",
		"yard.clean_prompt": "очистить оборудование",
		"yard.clean_title": "7. ОЧИСТКА",
		"yard.clean_description": "$5 → чистота 100%\nГрязь снижает цену продукта",
		"yard.brew_prompt": "сварить пиво",
		"yard.brew_title": "2. ПИВО",
		"yard.brew_description": "1 сырьё → варка 2 сек.\nБыстро, дёшево, легально",
		"yard.moonshine_prompt": "выгнать самогон",
		"yard.moonshine_title": "3. САМОГОН",
		"yard.moonshine_description": "1 сырьё → перегонка 4 сек.\nДорого, но растёт риск",
		"yard.wine_prompt": "поставить вино",
		"yard.wine_title": "4. ВИНО",
		"yard.wine_description": "1 сырьё → выдержка 7 сек.\nДолго, но легально и дороже",
		"yard.package_prompt": "разлить пиво по бутылкам",
		"yard.package_title": "3. УПАКОВКА ПИВА",
		"yard.package_description": "Готовое пиво + $2 → бутылка\nБез тары продавать нельзя",
		"yard.sell_prompt": "продать бутылку пива",
		"yard.sell_title": "4. ПРОДАЖА ПИВА",
		"yard.sell_description": "Бутылка пива → деньги\nЦена зависит от качества",
		"yard.black_market_prompt": "продать самогон",
		"yard.black_market_title": "7. ЧЁРНЫЙ РЫНОК",
		"yard.black_market_description": "Самогон → много денег + риск\n100 риска = облава и штраф",
		"yard.business_state": "СОСТОЯНИЕ БИЗНЕСА",
		"yard.message_placeholder": "Подсказка появится здесь",
		"business.station_use": "использовать станцию",
		"business.raw_at_warehouse": "Сырьё продаётся в складе-магазине в конце прямой дороги.",
		"business.no_money_raw": "Не хватает денег на пивное сырьё.",
		"business.bought_raw": "Склад: +%d пивного сырья за $%d.",
		"business.already_brewing": "Пиво уже варится: осталось %.1f сек.",
		"business.need_raw": "Для варки нужно 1 пивное сырьё. Купи его на складе.",
		"business.brew_started": "Варка запущена на %.1f сек. Чистота -15.",
		"business.beer_ready": "Пиво готово. Теперь упакуй его в бутылку.",
		"business.first_brew": "Сначала свари пиво.",
		"business.no_bottle_money": "Не хватает $%d на бутылку.",
		"business.packaged": "Пиво упаковано. Его можно продать.",
		"business.need_packaged": "Для продажи нужно упакованное пиво.",
		"business.sold": "Пиво продано легально за $%d.",
		"business.max_equipment": "Оборудование уже максимального уровня.",
		"business.need_upgrade_money": "Для улучшения нужно $%d.",
		"business.upgraded": "Оборудование улучшено до уровня %d.",
		"business.all_recipes": "Все простые пивные рецепты уже открыты.",
		"business.need_experiment": "Эксперимент требует 1 сырьё и $%d.",
		"business.recipe_opened": "Новый рецепт открыт. Уровень рецепта: %d.",
		"business.already_clean": "Оборудование уже чистое.",
		"business.need_clean_money": "Для очистки нужно $%d.",
		"business.cleaned": "Оборудование очищено до 100%.",
		"business.tier_3": "Tier 3: пивной завод",
		"business.tier_2": "Tier 2: мини-пивоварня",
		"business.tier_1": "Tier 1: гаражная пивоварня",
		"business.timer_ready": "готов",
		"business.timer_seconds": "%.1fс",
		"business.state": "СОСТОЯНИЕ ПИВОВАРНИ\nДеньги: $%d   Сырьё: %d   Результат: $%d\nКачество: оборудование %d + рецепт %d + чистота %d%%\nВарка: %s   Без тары: %d   В бутылках: %d\n%s",
	},
	"en": {
		"ui.inventory": "INVENTORY", "ui.active": "ACTIVE", "ui.items": "ITEMS",
		"ui.pause": "PAUSED", "ui.resume": "RESUME", "ui.quit": "QUIT GAME", "ui.language": "LANGUAGE",
		"ui.dialogue_placeholder": "Dialogue line", "ui.dialogue_footer": "[E] Next line     [Esc] Close",
		"brand.subtitle": "GARAGE BREWERY",
		"interaction.stand": "E — stand up", "interaction.charge_release": "Q — release for a strong throw",
		"interaction.place_throw": "Q — place / hold to throw", "interaction.pickup": "E — pick up: %s",
		"interaction.generic": "E — interact", "message.beer_drunk": "BEER DRUNK",
		"message.item_fell": "ITEM DROPPED FROM YOUR HANDS",
		"item.generic": "item", "item.mug": "beer mug", "item.mug_beer": "mug of beer",
		"item.bucket_empty": "empty bucket", "item.bucket_water": "bucket of water", "item.crate": "box",
		"item.toolbox": "toolbox", "item.tool": "tool", "item.tire": "tire", "item.extinguisher": "fire extinguisher",
		"item.malt_sack": "malt sack", "item.hops_crate": "hops crate", "item.yeast_box": "yeast box",
		"item.raw_barrel": "raw-material barrel", "item.garden_seed": "malt seeds",
		"item.garden_harvest": "malt", "item.flower": "Flower", "item.duck": "Duck",
		"ingredient.malt": "Malt", "ingredient.hops": "Hops", "ingredient.yeast": "Yeast",
		"bench.sit": "E — sit on the bench",
		"garden.seed_sign": "SEEDS FOR THE GARDEN BED", "garden.empty": "GARDEN BED — take a seed from the table",
		"garden.plant": "E — plant seed", "garden.planted": "SEED PLANTED",
		"garden.growing": "GROWING — %d%%", "garden.harvest": "E — harvest crop",
		"garden.harvested": "CROP HARVESTED",
		"vat.dry": "VAT — first add water from the bucket", "vat.ready": "VAT — add ingredients",
		"vat.add_water": "E — pour water into the vat", "vat.need_water": "Fill the bucket at the water pump first",
		"vat.fill_mug": "E — pour beer into the mug", "mug.drink": "E — drink beer",
		"brew.need_water": "ADD WATER TO THE VAT FIRST", "brew.enough_ingredient": "There is already enough of this ingredient",
		"brew.added": "Added: %s", "brew.ready": "BEER IS READY!",
		"brew.flower_no_surprise": "The flower vanished... but no surprise is assigned",
		"brew.duck_surprise": "A FLOWER?! THE VAT SPAT OUT A DUCK! QUACK!",
		"brew.first_brew": "Brew the beer first", "brew.mug_full": "The mug is already full",
		"brew.mug_filled": "Mug filled with beer", "brew.water_enough": "The vat already has enough water",
		"brew.water_added": "Water added to the vat — now add ingredients", "brew.water_yes": "FILLED", "brew.water_no": "NO",
		"brew.status": "Brewing — water: %s\nMalt %d/%d   Hops %d/%d   Yeast %d/%d\nE — pick up   Q — place / hold to throw",
		"brew.complete": "Recipe complete",
		"pump.prompt": "WATER PUMP — take a bucket and press E", "pump.bucket_full_message": "BUCKET IS ALREADY FULL",
		"pump.bucket_filled_message": "BUCKET FILLED WITH WATER", "pump.bucket_full": "The bucket is already full",
		"pump.fill": "E — fill the bucket with water",
		"light.label": "LIGHT", "light.enabled": "LIGHTS ON", "light.disabled": "LIGHTS OFF",
		"light.turn_off": "E — turn off the lights", "light.turn_on": "E — turn on the lights",
		"gate.label": "GATE", "gate.open": "E — open the gate", "gate.close": "E — close the gate",
		"gate.opening": "GATE OPENING", "gate.closing": "GATE CLOSING",
		"gate.close_outside": "Go outside to close the gate",
		"gallery.reset_label": "RESET", "gallery.goal": "KNOCK DOWN 3 TARGETS", "gallery.complete": "ALL DOWN!",
		"gallery.restored": "TARGETS RESET", "gallery.reset": "E — reset targets",
		"guide.world_label": "GUIDE", "guide.name": "Guide", "guide.prompt": "E — talk to: %s",
		"guide.no_lines": "I have no dialogue yet. Add lines in the Inspector.",
		"guide.line_1": "Hi! I'll help you brew your first beer.",
		"guide.line_2": "Aim at an ingredient and press E to pick it up.",
		"guide.line_3": "The recipe needs two portions of malt, one hops, and one yeast.",
		"guide.line_4": "Walk up to the vat, aim at it, and press E to add the ingredient.",
		"guide.line_5": "The counter on the left shows how many ingredients are already in the vat.",
		"guide.line_6": "If an item gets stuck, pick it up again and throw it a little higher over the rim.",
		"guide.line_7": "Once all four ingredients are in the vat, the beer will be ready!",
		"roulette.zero": "ZERO", "roulette.red": "RED", "roulette.black": "BLACK", "roulette.unknown": "UNKNOWN",
		"roulette.title": "ROULETTE", "roulette.zero_button": "ZERO  [E]", "roulette.red_button": "RED  [E]",
		"roulette.black_button": "BLACK  [E]", "roulette.idle": "CHOOSE A BET: ZERO / RED / BLACK",
		"roulette.prompt_zero": "E — bet on ZERO", "roulette.prompt_red": "E — bet on RED",
		"roulette.prompt_black": "E — bet on BLACK", "roulette.prompt_bet": "E — place a bet",
		"roulette.spinning_hover": "ROULETTE — the wheel is spinning...",
		"roulette.result_hover": "ROULETTE — %d, %s: %s", "roulette.aim": "ROULETTE — aim at a bet color",
		"roulette.won_short": "win", "roulette.lost_short": "lost", "roulette.already_spinning": "ROULETTE IS ALREADY SPINNING...",
		"roulette.spinning": "BET: %s\nSPINNING...", "roulette.won": "YOU WIN!", "roulette.lost": "NO LUCK",
		"roulette.result": "RESULT: %d — %s\n%s", "duck.sound": "QUACK?!",
		"warehouse.sign": "BEER SUPPLY WAREHOUSE\nMALT • HOPS • YEAST",
		"warehouse.buy_prompt": "buy 3 supply packs for $20",
		"warehouse.instructions": "1. BUY SUPPLIES\nE — malt, hops, and yeast pack",
		"yard.title": "TRAINING BREWERY\nsupplies → brewing → packaging → sales → upgrades",
		"yard.buy_prompt": "buy 3 supplies for $20", "yard.buy_title": "1. BUY SUPPLIES",
		"yard.buy_description": "Money → malt / fruit / sugar\nE: 3 supplies for $20",
		"yard.recipe_prompt": "unlock a new beer recipe", "yard.recipe_title": "5. BEER RECIPE",
		"yard.recipe_description": "Supplies + $30 → new variety\nRecipes increase beer value",
		"yard.upgrade_prompt": "upgrade equipment", "yard.upgrade_title": "6. UPGRADES",
		"yard.upgrade_description_old": "Money → equipment\nQuality and tier increase",
		"yard.upgrade_description": "Money → equipment\nBetter quality and faster brewing",
		"yard.clean_prompt": "clean equipment", "yard.clean_title": "7. CLEANING",
		"yard.clean_description": "$5 → 100% cleanliness\nDirt lowers the product value",
		"yard.brew_prompt": "brew beer", "yard.brew_title": "2. BEER",
		"yard.brew_description": "1 supply → brew for 2 sec.\nFast, cheap, legal",
		"yard.moonshine_prompt": "distill moonshine", "yard.moonshine_title": "3. MOONSHINE",
		"yard.moonshine_description": "1 supply → distill for 4 sec.\nProfitable, but risk increases",
		"yard.wine_prompt": "start wine", "yard.wine_title": "4. WINE",
		"yard.wine_description": "1 supply → age for 7 sec.\nSlow, legal, and more valuable",
		"yard.package_prompt": "bottle the beer", "yard.package_title": "3. BEER PACKAGING",
		"yard.package_description": "Finished beer + $2 → bottle\nUnpackaged beer cannot be sold",
		"yard.sell_prompt": "sell a bottle of beer", "yard.sell_title": "4. SELL BEER",
		"yard.sell_description": "Beer bottle → money\nPrice depends on quality",
		"yard.black_market_prompt": "sell moonshine", "yard.black_market_title": "7. BLACK MARKET",
		"yard.black_market_description": "Moonshine → more money + risk\n100 risk = raid and fine",
		"yard.business_state": "BUSINESS STATUS", "yard.message_placeholder": "A hint will appear here",
		"business.station_use": "use station", "business.raw_at_warehouse": "Supplies are sold at the warehouse at the end of the straight road.",
		"business.no_money_raw": "Not enough money for beer supplies.", "business.bought_raw": "Warehouse: +%d beer supplies for $%d.",
		"business.already_brewing": "Beer is already brewing: %.1f sec. left.",
		"business.need_raw": "Brewing needs 1 supply. Buy it at the warehouse.",
		"business.brew_started": "Brewing started for %.1f sec. Cleanliness -15.",
		"business.beer_ready": "Beer is ready. Now bottle it.", "business.first_brew": "Brew beer first.",
		"business.no_bottle_money": "You need $%d for a bottle.", "business.packaged": "Beer bottled. It can now be sold.",
		"business.need_packaged": "You need bottled beer to sell it.", "business.sold": "Beer legally sold for $%d.",
		"business.max_equipment": "Equipment is already at maximum level.",
		"business.need_upgrade_money": "You need $%d for the upgrade.", "business.upgraded": "Equipment upgraded to level %d.",
		"business.all_recipes": "All basic beer recipes are already unlocked.",
		"business.need_experiment": "The experiment needs 1 supply and $%d.",
		"business.recipe_opened": "New recipe unlocked. Recipe level: %d.", "business.already_clean": "Equipment is already clean.",
		"business.need_clean_money": "You need $%d for cleaning.", "business.cleaned": "Equipment cleaned to 100%.",
		"business.tier_3": "Tier 3: beer factory", "business.tier_2": "Tier 2: microbrewery",
		"business.tier_1": "Tier 1: garage brewery", "business.timer_ready": "ready", "business.timer_seconds": "%.1fs",
		"business.state": "BREWERY STATUS\nMoney: $%d   Supplies: %d   Net: $%d\nQuality: equipment %d + recipe %d + cleanliness %d%%\nBrewing: %s   Unbottled: %d   Bottled: %d\n%s",
	},
	"es": {
		"ui.inventory": "INVENTARIO", "ui.active": "ACTIVOS", "ui.items": "OBJETOS",
		"ui.pause": "PAUSA", "ui.resume": "CONTINUAR", "ui.quit": "SALIR DEL JUEGO", "ui.language": "IDIOMA",
		"ui.dialogue_placeholder": "Línea de diálogo", "ui.dialogue_footer": "[E] Siguiente frase     [Esc] Cerrar",
		"brand.subtitle": "CERVECERÍA DEL GARAJE",
		"interaction.stand": "E — levantarse", "interaction.charge_release": "Q — suelta para lanzar fuerte",
		"interaction.place_throw": "Q — colocar / mantener para lanzar", "interaction.pickup": "E — recoger: %s",
		"interaction.generic": "E — interactuar", "message.beer_drunk": "CERVEZA BEBIDA",
		"message.item_fell": "EL OBJETO CAYÓ DE TUS MANOS",
		"item.generic": "objeto", "item.mug": "jarra de cerveza", "item.mug_beer": "jarra con cerveza",
		"item.bucket_empty": "cubo vacío", "item.bucket_water": "cubo con agua", "item.crate": "caja",
		"item.toolbox": "caja de herramientas", "item.tool": "herramienta", "item.tire": "neumático",
		"item.extinguisher": "extintor", "item.malt_sack": "saco de malta", "item.hops_crate": "caja de lúpulo",
		"item.yeast_box": "caja de levadura", "item.raw_barrel": "barril de suministros",
		"item.garden_seed": "semillas de malta", "item.garden_harvest": "malta",
		"item.flower": "Flor", "item.duck": "Pato",
		"ingredient.malt": "Malta", "ingredient.hops": "Lúpulo", "ingredient.yeast": "Levadura",
		"bench.sit": "E — sentarse en el banco",
		"garden.seed_sign": "SEMILLAS PARA EL HUERTO", "garden.empty": "HUERTO — toma una semilla de la mesa",
		"garden.plant": "E — plantar semilla", "garden.planted": "SEMILLA PLANTADA",
		"garden.growing": "CRECIENDO — %d%%", "garden.harvest": "E — recoger cosecha",
		"garden.harvested": "COSECHA RECOGIDA",
		"vat.dry": "TINA — primero añade agua con el cubo", "vat.ready": "TINA — añade los ingredientes",
		"vat.add_water": "E — verter agua en la tina", "vat.need_water": "Primero llena el cubo en la bomba de agua",
		"vat.fill_mug": "E — llenar la jarra de cerveza", "mug.drink": "E — beber cerveza",
		"brew.need_water": "PRIMERO AÑADE AGUA A LA TINA", "brew.enough_ingredient": "Ya hay suficiente de este ingrediente",
		"brew.added": "Añadido: %s", "brew.ready": "¡CERVEZA LISTA!",
		"brew.flower_no_surprise": "La flor desapareció... pero no hay sorpresa asignada",
		"brew.duck_surprise": "¿UNA FLOR? ¡LA TINA ESCUPIÓ UN PATO! ¡CUAC!",
		"brew.first_brew": "Primero elabora la cerveza", "brew.mug_full": "La jarra ya está llena",
		"brew.mug_filled": "Jarra llena de cerveza", "brew.water_enough": "La tina ya tiene suficiente agua",
		"brew.water_added": "Agua añadida — ahora agrega los ingredientes", "brew.water_yes": "LLENA", "brew.water_no": "NO",
		"brew.status": "Elaboración — agua: %s\nMalta %d/%d   Lúpulo %d/%d   Levadura %d/%d\nE — recoger   Q — colocar / mantener para lanzar",
		"brew.complete": "Receta completada",
		"pump.prompt": "BOMBA DE AGUA — toma un cubo y pulsa E", "pump.bucket_full_message": "EL CUBO YA ESTÁ LLENO",
		"pump.bucket_filled_message": "CUBO LLENO DE AGUA", "pump.bucket_full": "El cubo ya está lleno",
		"pump.fill": "E — llenar el cubo con agua",
		"light.label": "LUZ", "light.enabled": "LUCES ENCENDIDAS", "light.disabled": "LUCES APAGADAS",
		"light.turn_off": "E — apagar las luces", "light.turn_on": "E — encender las luces",
		"gate.label": "PORTÓN", "gate.open": "E — abrir el portón", "gate.close": "E — cerrar el portón",
		"gate.opening": "ABRIENDO EL PORTÓN", "gate.closing": "CERRANDO EL PORTÓN",
		"gate.close_outside": "Sal fuera para cerrar el portón",
		"gallery.reset_label": "REINICIAR", "gallery.goal": "DERRIBA 3 DIANAS", "gallery.complete": "¡TODAS DERRIBADAS!",
		"gallery.restored": "DIANAS RESTABLECIDAS", "gallery.reset": "E — restablecer dianas",
		"guide.world_label": "GUÍA", "guide.name": "Guía", "guide.prompt": "E — hablar con: %s",
		"guide.no_lines": "Todavía no tengo frases. Añádelas en el Inspector.",
		"guide.line_1": "¡Hola! Te ayudaré a elaborar tu primera cerveza.",
		"guide.line_2": "Apunta a un ingrediente y pulsa E para recogerlo.",
		"guide.line_3": "La receta necesita dos porciones de malta, una de lúpulo y una de levadura.",
		"guide.line_4": "Acércate a la tina, apunta hacia ella y pulsa E para añadir el ingrediente.",
		"guide.line_5": "El contador de la izquierda muestra cuántos ingredientes hay en la tina.",
		"guide.line_6": "Si un objeto se atasca, recógelo y lánzalo un poco más alto sobre el borde.",
		"guide.line_7": "Cuando los cuatro ingredientes estén dentro, ¡la cerveza estará lista!",
		"roulette.zero": "CERO", "roulette.red": "ROJO", "roulette.black": "NEGRO", "roulette.unknown": "DESCONOCIDO",
		"roulette.title": "RULETA", "roulette.zero_button": "CERO  [E]", "roulette.red_button": "ROJO  [E]",
		"roulette.black_button": "NEGRO  [E]", "roulette.idle": "ELIGE APUESTA: CERO / ROJO / NEGRO",
		"roulette.prompt_zero": "E — apostar al CERO", "roulette.prompt_red": "E — apostar al ROJO",
		"roulette.prompt_black": "E — apostar al NEGRO", "roulette.prompt_bet": "E — hacer una apuesta",
		"roulette.spinning_hover": "RULETA — la rueda está girando...",
		"roulette.result_hover": "RULETA — salió %d, %s: %s", "roulette.aim": "RULETA — apunta al color de una apuesta",
		"roulette.won_short": "ganaste", "roulette.lost_short": "sin suerte",
		"roulette.already_spinning": "LA RULETA YA ESTÁ GIRANDO...", "roulette.spinning": "APUESTA: %s\nGIRANDO...",
		"roulette.won": "¡GANASTE!", "roulette.lost": "SIN SUERTE", "roulette.result": "SALIÓ: %d — %s\n%s",
		"duck.sound": "¿CUAC?!",
		"warehouse.sign": "ALMACÉN DE INSUMOS\nMALTA • LÚPULO • LEVADURA",
		"warehouse.buy_prompt": "comprar 3 lotes de insumos por $20",
		"warehouse.instructions": "1. COMPRAR INSUMOS\nE — lote de malta, lúpulo y levadura",
		"yard.title": "CERVECERÍA DE PRÁCTICA\ninsumos → elaboración → embotellado → venta → mejoras",
		"yard.buy_prompt": "comprar 3 insumos por $20", "yard.buy_title": "1. COMPRAR INSUMOS",
		"yard.buy_description": "Dinero → malta / fruta / azúcar\nE: 3 insumos por $20",
		"yard.recipe_prompt": "desbloquear una receta de cerveza", "yard.recipe_title": "5. RECETA DE CERVEZA",
		"yard.recipe_description": "Insumos + $30 → nueva variedad\nLas recetas aumentan el precio",
		"yard.upgrade_prompt": "mejorar el equipo", "yard.upgrade_title": "6. MEJORAS",
		"yard.upgrade_description_old": "Dinero → equipo\nSuben la calidad y el nivel",
		"yard.upgrade_description": "Dinero → equipo\nMás calidad y elaboración más rápida",
		"yard.clean_prompt": "limpiar el equipo", "yard.clean_title": "7. LIMPIEZA",
		"yard.clean_description": "$5 → limpieza al 100%\nLa suciedad reduce el precio",
		"yard.brew_prompt": "elaborar cerveza", "yard.brew_title": "2. CERVEZA",
		"yard.brew_description": "1 insumo → elaborar 2 s.\nRápido, barato y legal",
		"yard.moonshine_prompt": "destilar aguardiente", "yard.moonshine_title": "3. AGUARDIENTE",
		"yard.moonshine_description": "1 insumo → destilar 4 s.\nRentable, pero aumenta el riesgo",
		"yard.wine_prompt": "preparar vino", "yard.wine_title": "4. VINO",
		"yard.wine_description": "1 insumo → añejar 7 s.\nLento, legal y más valioso",
		"yard.package_prompt": "embotellar la cerveza", "yard.package_title": "3. EMBOTELLADO",
		"yard.package_description": "Cerveza lista + $2 → botella\nNo se vende sin embotellar",
		"yard.sell_prompt": "vender una botella de cerveza", "yard.sell_title": "4. VENDER CERVEZA",
		"yard.sell_description": "Botella de cerveza → dinero\nEl precio depende de la calidad",
		"yard.black_market_prompt": "vender aguardiente", "yard.black_market_title": "7. MERCADO NEGRO",
		"yard.black_market_description": "Aguardiente → más dinero + riesgo\n100 de riesgo = redada y multa",
		"yard.business_state": "ESTADO DEL NEGOCIO", "yard.message_placeholder": "Aquí aparecerá una pista",
		"business.station_use": "usar estación", "business.raw_at_warehouse": "Los insumos se venden en el almacén al final del camino recto.",
		"business.no_money_raw": "No hay dinero suficiente para insumos.",
		"business.bought_raw": "Almacén: +%d insumos por $%d.",
		"business.already_brewing": "La cerveza ya se elabora: faltan %.1f s.",
		"business.need_raw": "Se necesita 1 insumo. Cómpralo en el almacén.",
		"business.brew_started": "Elaboración iniciada por %.1f s. Limpieza -15.",
		"business.beer_ready": "Cerveza lista. Ahora embotéllala.", "business.first_brew": "Primero elabora cerveza.",
		"business.no_bottle_money": "Necesitas $%d para una botella.", "business.packaged": "Cerveza embotellada. Ya se puede vender.",
		"business.need_packaged": "Necesitas cerveza embotellada para vender.", "business.sold": "Cerveza vendida legalmente por $%d.",
		"business.max_equipment": "El equipo ya está al nivel máximo.",
		"business.need_upgrade_money": "Necesitas $%d para la mejora.", "business.upgraded": "Equipo mejorado al nivel %d.",
		"business.all_recipes": "Todas las recetas básicas ya están desbloqueadas.",
		"business.need_experiment": "El experimento necesita 1 insumo y $%d.",
		"business.recipe_opened": "Nueva receta desbloqueada. Nivel: %d.", "business.already_clean": "El equipo ya está limpio.",
		"business.need_clean_money": "Necesitas $%d para limpiar.", "business.cleaned": "Equipo limpiado al 100%.",
		"business.tier_3": "Nivel 3: fábrica de cerveza", "business.tier_2": "Nivel 2: microcervecería",
		"business.tier_1": "Nivel 1: cervecería de garaje", "business.timer_ready": "lista", "business.timer_seconds": "%.1fs",
		"business.state": "ESTADO DE LA CERVECERÍA\nDinero: $%d   Insumos: %d   Neto: $%d\nCalidad: equipo %d + receta %d + limpieza %d%%\nElaboración: %s   Sin embotellar: %d   Embotelladas: %d\n%s",
	},
}

var current_language := DEFAULT_LANGUAGE
var _source_to_key: Dictionary = {}


func _ready() -> void:
	_build_source_index()
	_load_language()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("localize_tree", get_tree().root)


func get_text(key: String, values: Array = []) -> String:
	var language_table: Dictionary = TEXTS.get(current_language, TEXTS[DEFAULT_LANGUAGE])
	var fallback_table: Dictionary = TEXTS[DEFAULT_LANGUAGE]
	var template := String(language_table.get(key, fallback_table.get(key, key)))
	if values.is_empty():
		return template
	if values.size() == 1:
		return template % values[0]
	return template % values


# Переводит известный текст из Inspector. Неизвестный пользовательский текст
# не трогается, поэтому редактируемые сцены остаются удобными.
func translate_source(source: String) -> String:
	var key := String(_source_to_key.get(source, ""))
	return get_text(key) if not key.is_empty() else source


func key_for_source(source: String) -> String:
	return String(_source_to_key.get(source, ""))


func set_language(language_code: String, save_setting := true) -> void:
	var normalized := language_code.to_lower().left(2)
	if normalized not in SUPPORTED_LANGUAGES:
		normalized = DEFAULT_LANGUAGE
	var changed := current_language != normalized
	current_language = normalized
	TranslationServer.set_locale(normalized)
	localize_tree(get_tree().root)
	if save_setting:
		_save_language()
	if changed:
		language_changed.emit(current_language)


func get_language_name(language_code: String) -> String:
	return String(LANGUAGE_NAMES.get(language_code, language_code))


func get_language_index() -> int:
	return maxi(SUPPORTED_LANGUAGES.find(current_language), 0)


func localize_tree(root: Node) -> void:
	if root == null:
		return
	_localize_node(root)
	for child in root.get_children():
		localize_tree(child)


func _localize_node(node: Node) -> void:
	if not (node is Label or node is Button or node is Label3D):
		return
	var key := String(node.get_meta("localization_key", ""))
	if key.is_empty():
		key = key_for_source(String(node.get("text")))
		if not key.is_empty():
			node.set_meta("localization_key", key)
	if not key.is_empty():
		node.set("text", get_text(key))


func _on_node_added(node: Node) -> void:
	call_deferred("_localize_node", node)


func _build_source_index() -> void:
	_source_to_key.clear()
	for language_code in SUPPORTED_LANGUAGES:
		var language_table: Dictionary = TEXTS[language_code]
		for key in language_table:
			var source := String(language_table[key])
			# Обычный знак процента (например, "100%") — часть подписи.
			# Исключаем только шаблоны, которым при переводе нужны аргументы.
			if not source.contains("%s") and not source.contains("%d") and not source.contains("%."):
				_source_to_key[source] = key


func _load_language() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		current_language = String(config.get_value(
			SETTINGS_SECTION,
			SETTINGS_KEY,
			DEFAULT_LANGUAGE
		)).to_lower().left(2)
	if current_language not in SUPPORTED_LANGUAGES:
		current_language = DEFAULT_LANGUAGE
	TranslationServer.set_locale(current_language)


func _save_language() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, current_language)
	config.save(SETTINGS_PATH)
