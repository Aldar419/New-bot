import os
from aiogram import Bot, Dispatcher, types
from aiogram.types import ReplyKeyboardMarkup, KeyboardButton
from aiogram.fsm.state import StatesGroup, State
from aiogram.fsm.context import FSMContext
from aiogram.fsm.storage.memory import MemoryStorage
import asyncio

BOT_TOKEN = os.getenv("BOT_TOKEN")
ADMIN_ID = int(os.getenv("ADMIN_ID"))

bot = Bot(token=BOT_TOKEN)
dp = Dispatcher(storage=MemoryStorage())


# ---------- СОСТОЯНИЯ ----------
class Sale(StatesGroup):
    description = State()
    photos = State()
    price = State()


class Help(StatesGroup):
    description = State()
    price = State()


class Service(StatesGroup):
    description = State()
    price = State()


# ---------- КНОПКИ ----------
menu = ReplyKeyboardMarkup(
    keyboard=[
        [KeyboardButton(text="Продажа вещи")],
        [KeyboardButton(text="Помощь")],
        [KeyboardButton(text="Предложение услуги")]
    ],
    resize_keyboard=True
)


# ---------- START ----------
@dp.message(commands=["start"])
async def start(message: types.Message):
    await message.answer(
        "Выберите нужный пункт:",
        reply_markup=menu
    )


# ---------- ПРОДАЖА ----------
@dp.message(lambda m: m.text == "Продажа вещи")
async def sale_start(message: types.Message, state: FSMContext):
    await state.set_state(Sale.description)
    await message.answer("Опишите вещь:")


@dp.message(Sale.description)
async def sale_desc(message: types.Message, state: FSMContext):
    await state.update_data(description=message.text)
    await state.set_state(Sale.photos)
    await message.answer("Отправьте фото товара (можно несколько). Когда закончите — напишите 'Готово'")


@dp.message(Sale.photos)
async def sale_photos(message: types.Message, state: FSMContext):
    data = await state.get_data()
    photos = data.get("photos", [])

    if message.photo:
        photos.append(message.photo[-1].file_id)
        await state.update_data(photos=photos)
    elif message.text.lower() == "готово":
        await state.set_state(Sale.price)
        await message.answer("Укажите цену:")


@dp.message(Sale.price)
async def sale_price(message: types.Message, state: FSMContext):
    data = await state.get_data()

    text = (
        "🛒 *Продажа вещи*\n\n"
        f"📄 Описание: {data['description']}\n"
        f"💰 Цена: {message.text}"
    )

    await bot.send_message(ADMIN_ID, text, parse_mode="Markdown")

    for photo in data.get("photos", []):
        await bot.send_photo(ADMIN_ID, photo)

    await state.clear()
    await message.answer("Заявка отправлена админу ✅", reply_markup=menu)


# ---------- ПОМОЩЬ ----------
@dp.message(lambda m: m.text == "Помощь")
async def help_start(message: types.Message, state: FSMContext):
    await state.set_state(Help.description)
    await message.answer("Опишите, какая помощь нужна:")


@dp.message(Help.description)
async def help_desc(message: types.Message, state: FSMContext):
    await state.update_data(description=message.text)
    await state.set_state(Help.price)
    await message.answer("Укажите цену:")


@dp.message(Help.price)
async def help_price(message: types.Message, state: FSMContext):
    data = await state.get_data()

    await bot.send_message(
        ADMIN_ID,
        f"🆘 *Помощь*\n\n📄 {data['description']}\n💰 {message.text}",
        parse_mode="Markdown"
    )

    await state.clear()
    await message.answer("Заявка отправлена админу ✅", reply_markup=menu)


# ---------- УСЛУГИ ----------
@dp.message(lambda m: m.text == "Предложение услуги")
async def service_start(message: types.Message, state: FSMContext):
    await state.set_state(Service.description)
    await message.answer("Опишите услугу:")


@dp.message(Service.description)
async def service_desc(message: types.Message, state: FSMContext):
    await state.update_data(description=message.text)
    await state.set_state(Service.price)
    await message.answer("Укажите цену:")


@dp.message(Service.price)
async def service_price(message: types.Message, state: FSMContext):
    data = await state.get_data()

    await bot.send_message(
      ADMIN_ID,
        f"🛠 *Услуга*\n\n📄 {data['description']}\n💰 {message.text}",
        parse_mode="Markdown"
    )

    await state.clear()
    await message.answer("Заявка отправлена админу ✅", reply_markup=menu)


# ---------- ЗАПУСК ----------
async def main():
    await dp.start_polling(bot)

if name == "__main__":
    asyncio.run(main())
