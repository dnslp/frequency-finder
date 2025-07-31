import SwiftUI

struct ReadingPassage: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let skillFocus: String
}

extension ReadingPassage {
    static let passages: [ReadingPassage] = [
        ReadingPassage(
            title: "Rainbows and Light",
            text: """
            When the sunlight strikes raindrops in the air, they act as a prism and form a rainbow. The rainbow is a division of white light into many beautiful colors. These take the shape of a long round arch, with its path high above, and its two ends apparently beyond the horizon.

            There is, according to legend, a boiling pot of gold at one end. People look, but no one ever finds it. When a man looks for something beyond his reach, his friends say he is looking for the pot of gold at the end of the rainbow. Throughout the centuries people have explained the rainbow in various ways. Some have accepted it as a miracle without physical explanation. To the Hebrews it was a token that there would be no more universal floods.

            The Greeks used to imagine that it was a sign from the gods to foretell war or heavy rain. The Norsemen considered the rainbow as a bridge over which the gods passed from earth to their home in the sky. Others have tried to explain the phenomenon physically. Aristotle thought that the rainbow was caused by reflection of the sun's rays by the rain. Since then physicists have found that it is not reflection, but refraction by the raindrops which causes the rainbows.
            """,
            skillFocus: "Clarity"
        ),
        ReadingPassage(
            title: "The Moon’s Mysteries",
            text: """
            The moon, a celestial beacon, has fascinated humanity since time immemorial. Its pale, luminous glow casts a serene light across the night sky, influencing tides and inspiring countless myths and legends. As it orbits the Earth, the moon goes through phases, from the slender crescent to the full, round brilliance that illuminates the darkness.

            In ancient times, civilizations built their calendars around the lunar cycle, tracking the passage of months by observing its changes. Astronomers and poets alike have gazed at the moon, finding inspiration in its ever-changing face. The surface of the moon, marked by craters and ancient volcanic plains, tells the story of its turbulent past.

            During a total lunar eclipse, the moon takes on a reddish hue, earning the nickname "blood moon." This phenomenon occurs when the Earth comes between the sun and the moon, casting a shadow that transforms its usual silvery appearance. The moon landings of the 20th century brought this distant world closer, as astronauts set foot on its barren landscape and brought back samples for study.

            Legends speak of moon goddesses and mythical creatures that inhabit this glowing orb. The moon continues to be a source of wonder, its silent presence a reminder of the vastness and mystery of the universe. Whether observed through a telescope or admired with the naked eye, the moon remains a symbol of beauty and enigma.
            """,
            skillFocus: "Storytelling"
        ),
        ReadingPassage(
            title: "The Art of Bread",
            text: """
            Baking bread is an ancient craft, cherished across cultures and generations. First, gather your ingredients: flour, yeast, salt, and water. Mix them gently until a soft dough forms. Knead it thoroughly, pressing and folding, feeling it transform beneath your hands. As it rises, it doubles in size, the yeast working its magic, creating pockets of air that will give the bread its soft, airy texture.

            Shape the dough into a loaf, then let it rise again, covering it with a damp cloth. Preheat your oven, a necessary step to transform the dough into golden perfection. The scent of baking bread fills the kitchen, a comforting aroma that promises warmth and nourishment. When the crust is golden and firm, remove the loaf and let it cool, resisting the temptation to slice it too soon.

            The first bite of fresh, homemade bread is a delight, the crust crisp and the interior soft and warm. Each slice carries the essence of the baker's skill and patience, a testament to the timeless art of bread-making.
            """,
            skillFocus: "Warmth"
        ),
        ReadingPassage(
            title: "Dragons: Myths & Legends",
            text: """
            Dragons, majestic and mythical, have captivated imaginations for centuries. These legendary creatures, with scales that shimmer in the sunlight, wings that span the sky, and fiery breath, are both feared and revered. In tales of old, dragons guarded vast treasures, their lairs hidden in mountains or deep within enchanted forests.

            Heroes and knights sought to challenge these beasts, embarking on quests filled with peril. The roar of a dragon could beHeard for miles, a sound that struck fear into the hearts of villagers. Yet, not all dragons were foes; some were wise and noble, bestowing knowledge and gifts upon those deemed worthy.

            Their eyes, often described as piercing and intelligent, seemed to hold the secrets of the ages. The bond between dragon and rider, in some stories, was one of deep trust and mutual respect. These partnerships, though rare, led to epic adventures and the forging of unbreakable alliances.

            In modern fantasy, dragons continue to soar across the pages of books and screens of movies, their legacy enduring. They symbolize power, wisdom, and mystery, a testament to the enduring allure of these magnificent creatures.
            """,
            skillFocus: "Authority"
        ),
    ]
}
