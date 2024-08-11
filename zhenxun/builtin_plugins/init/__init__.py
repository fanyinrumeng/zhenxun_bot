from pathlib import Path

import nonebot
from nonebot.adapters import Bot

from zhenxun.models.group_console import GroupConsole
from zhenxun.services.log import logger
from zhenxun.utils.platform import PlatformUtils

nonebot.load_plugins(str(Path(__file__).parent.resolve()))


driver = nonebot.get_driver()


@driver.on_bot_connect
async def _(bot: Bot):
    """将bot已存在的群组添加群认证

    参数:
        bot: Bot
    """
    if PlatformUtils.get_platform(bot) == "qq":
        logger.debug(f"更新Bot: {bot.self_id} 的群认证...")
        group_list, _ = await PlatformUtils.get_group_list(bot)
        gid_list = [g.group_id for g in group_list]
        db_group_list = await GroupConsole.all().values_list("group_id", flat=True)
        create_list = []
        update_id = []
        for gid in gid_list:
            if gid not in db_group_list:
                create_list.append(GroupConsole(group_id=gid, group_flag=1))
            else:
                update_id.append(gid)
        if create_list:
            await GroupConsole.bulk_create(create_list, 10)
        else:
            await GroupConsole.filter(group_id__in=update_id).update(group_flag=1)
        logger.debug(
            f"更新Bot: {bot.self_id} 的群认证完成，共创建 {len(create_list)} 条数据，共修改 {len(update_id)} 条数据..."
        )